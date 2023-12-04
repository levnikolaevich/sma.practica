import asyncio
from typing import Dict
import numpy as np
import gym
import cma
import re
from gama_client.sync_client import GamaSyncClient
from gama_client.message_types import MessageTypes
from tqdm import tqdm


async def async_command_answer_handler(message: Dict):
    # print("Here is the answer to an async command: ", message)
    pass


async def gama_server_message_handler(message: Dict):
    # print("I just received a message from Gama-server and it's not an answer to a command!")
    # print("Here it is:", message)
    pass


class GamaGymEnv(gym.Env):
    def __init__(self):
        server_url = "localhost"
        server_port = 6868
        self.client = GamaSyncClient(server_url, server_port, async_command_answer_handler, gama_server_message_handler)

        self.experiment_id = ''
        self.number_agents = 50  # Количество агентов

        # Определение пространства действий и наблюдений
        self.action_space = gym.spaces.Box(low=-50.0, high=50.0, shape=(self.number_agents,))
        self.observation_space = gym.spaces.Box(
            low=np.array([0, 0, 0] * self.number_agents),
            high=np.array([100, 100, 141.42] * self.number_agents),
            shape=(self.number_agents, 3)
        )

    async def __aenter__(self):
        print("connecting to Gama server")
        await self.client.connect()
        return self

    async def __aexit__(self, exc_type, exc_value, traceback):
        print("killing the simulation")
        gama_response = self.client.sync_stop(self.experiment_id)
        if gama_response["type"] != MessageTypes.CommandExecutedSuccessfully.value:
            print("Unable to stop the experiment", gama_response)
        print("closing socket just to be sure")
        self.client.sync_close_connection()

    def load(self, gaml_file_path, exp_name, exp_parameters):
        print("initialize a gaml model")
        gama_response = self.client.sync_load(gaml_file_path, exp_name, True, True, True, True,
                                              parameters=exp_parameters)
        try:
            self.experiment_id = gama_response["content"]
            print(f"experiment_id {self.experiment_id}")

            # gama_response = self.client.sync_play(self.experiment_id)

            if gama_response["type"] != MessageTypes.CommandExecutedSuccessfully.value:
                print("error while trying to run the experiment", gama_response)
                print("initialization successful, running the model")
            else:
                print("Have run the experiment", gama_response)

        except Exception as e:
            print("error while initializing", gama_response, e)

    def step(self, action):
        matrix_vt = np.full((self.number_agents, 1), 2.0)
        # matrix_vr = np.random.uniform(-50.0, 50.0, size=(self.number_agents, 1))

        # Преобразование матриц NumPy в строки для GAMA запроса
        vt_str = ','.join([str(v[0]) for v in matrix_vt])
        vr_str = ','.join([str(v[0]) for v in action])

        # Формирование строки запроса
        gama_command = f"ask world {{ do set_agents_vel(matrix([{vt_str}]),matrix([{vr_str}])); }}"
        self.client.sync_expression(self.experiment_id, gama_command)

        self.client.sync_step(self.experiment_id)

        cycle_response = self.client.sync_expression(self.experiment_id, r"cycle")["content"]
        cycle_num = int(cycle_response)
        print("asking simulation the value of: cycle=", cycle_num)

        points_response = \
        self.client.sync_expression(self.experiment_id, r"ask world { do get_agents_pos(); }")[
            "content"]
        matches = re.findall(r'\{x=([\d.\-]+), y=([\d.\-]+), d=([\d.\-]+)}', points_response)
        points_set = set((round(float(x), 2), round(float(y), 2), round(float(d), 2)) for x, y, d in matches)
        obs = len(points_set)

        # Вычисление вознаграждения и проверка завершения эпизода
        reward = self.compute_reward(obs)
        done = self.is_done(obs, cycle_num)
        asyncio.sleep(1)
        return np.array(obs), reward, done, {}

    def compute_reward(self, number_of_live_points):
        # Больше вознаграждения за большее количество оставшихся живых точек
        reward = number_of_live_points
        return reward

    def is_done(self, number_of_live_points, current_step):
        # Эпизод завершается, если нет живых точек или если прошло 4850 шагов
        done = number_of_live_points == 0 or current_step >= 4850
        return done


async def run_cmaes(env, episodes=100, steps=5000):
    # Функция приспособленности для оптимизации CMA-ES
    def fitness_function(x):
        total_reward = 0
        for _ in tqdm(range(episodes)):  # Здесь определяется количество эпизодов
            env.reset()  # Начало нового эпизода
            for _ in tqdm(range(steps)):  # Для каждого шага в эпизоде
                obs, reward, done, _ = env.step(x)  # Выполнение шага
                total_reward += reward
                if done:
                    break
        return -total_reward

    # Инициализация CMA-ES
    es = cma.CMAEvolutionStrategy(np.zeros(env.number_agents), 0.5)

    # Основной цикл оптимизации
    while not es.stop():
        solutions = es.ask()
        es.tell(solutions, [fitness_function(x) for x in solutions])
        es.logger.add()
        es.disp()

    # Лучшее найденное решение
    best_solution = es.result.xbest
    print('Лучшее найденное решение:', best_solution)


async def main():
    # Experiment and Gama-server constants
    gaml_file_path = str("D:/Development/UNIVERSIDAD/SMA/sma.practica/P2_Robots_LevBerezhnoy.gaml")
    exp_name = "Robots_experimento"
    exp_parameters = [{"type": "int", "name": "number_agentes", "value": 50}]

    async with GamaGymEnv() as env:
        env.load(gaml_file_path, exp_name, exp_parameters)
        await run_cmaes(env)

        # step = 0
        # while step < 10:
        #     matrix_vt = np.full((env.number_agents, 1), 2.0)
        #     matrix_vr = np.random.uniform(-50.0, 50.0, size=(env.number_agents, 1))
        #
        #     # Преобразование матриц NumPy в строки для GAMA запроса
        #     vt_str = ','.join([str(v[0]) for v in matrix_vt])
        #     vr_str = ','.join([str(v[0]) for v in matrix_vr])
        #
        #     # Формирование строки запроса
        #     gama_command = f"ask world {{ do set_agents_vel(matrix([{vt_str}]),matrix([{vr_str}])); }}"
        #     env.client.sync_expression(env.experiment_id, gama_command)
        #
        #     env.client.sync_step(env.experiment_id)
        #
        #     cycle_response = env.client.sync_expression(env.experiment_id, r"cycle")["content"]
        #     print("asking simulation the value of: cycle=", int(cycle_response))
        #
        #     points_response = env.client.sync_expression(env.experiment_id, r"ask world { do get_agents_pos(); }")[
        #         "content"]
        #     matches = re.findall(r'\{x=([\d.\-]+), y=([\d.\-]+), d=([\d.\-]+)}', points_response)
        #     points_set = set((round(float(x), 2), round(float(y), 2), round(float(d), 2)) for x, y, d in matches)
        #     print("asking simulation the value of: points=", points_set)
        #
        #     step += 1
        #     await asyncio.sleep(1)


if __name__ == "__gym-control__":
    asyncio.run(main())
