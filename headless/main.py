import asyncio
from typing import Dict
import numpy as np
import gym
import cma
from gama_client.sync_client import GamaSyncClient
from gama_client.message_types import MessageTypes


async def async_command_answer_handler(message: Dict):
    #print("Here is the answer to an async command: ", message)
    pass


async def gama_server_message_handler(message: Dict):
    #print("I just received a message from Gama-server and it's not an answer to a command!")
    #print("Here it is:", message)
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
        self.observation_space = gym.spaces.Box(low=-np.inf, high=np.inf, shape=(self.number_agents, 2))

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

    def run(self, gaml_file_path, exp_name, exp_parameters):
        print("initialize a gaml model")
        gama_response = self.client.sync_load(gaml_file_path, exp_name, True, True, True, True,
                                              parameters=exp_parameters)
        try:
            self.experiment_id = gama_response["content"]
            print(f"experiment_id {self.experiment_id}")

            gama_response = self.client.sync_play(self.experiment_id)

            if gama_response["type"] != MessageTypes.CommandExecutedSuccessfully.value:
                print("error while trying to run the experiment", gama_response)
                print("initialization successful, running the model")
            else:
                print("Have run the experiment", gama_response)

        except Exception as e:
            print("error while initializing", gama_response, e)

    def step(self, action):
        # Отправка действия в GAMA и получение нового состояния
        self.client.sync_expression(self.experiment_id, f"do set_agents_vel({action.tolist()}, {action.tolist()})")
        obs = self.client.sync_expression(self.experiment_id, "ask world { do get_agents_pos(); }")["content"]

        # Вычисление вознаграждения и проверка завершения эпизода
        reward = self.compute_reward(obs)
        done = self.is_done(obs)

        return np.array(obs), reward, done, {}


async def run_cmaes(env):
    # Функция приспособленности для оптимизации CMA-ES
    def fitness_function(x):
        total_reward = 0
        obs = env.reset()
        for _ in range(5000):  # Допустим, у нас есть 10 шагов в каждом эпизоде
            obs, reward, done, _ = env.step(x)
            total_reward += reward
            if done:
                break
        return -total_reward  # CMA-ES минимизирует функцию, поэтому ставим минус

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
    exp_parameters = [{"type": "int", "name": "number_agentes", "value": 55}]

    async with GamaGymEnv() as env:
        env.run(gaml_file_path, exp_name, exp_parameters)
        # await run_cmaes(env)

        step = 0
        while step < 10:
            # Предположим, что matrix_vt и matrix_vr уже созданы
            matrix_vt = np.full((env.number_agents, 1), 2.0)
            matrix_vr = np.random.uniform(-50.0, 50.0, size=(env.number_agents, 1))

            # Преобразование матриц NumPy в строки для GAMA запроса
            vt_str = ','.join([str(v[0]) for v in matrix_vt])
            vr_str = ','.join([str(v[0]) for v in matrix_vr])

            # Формирование строки запроса
            gama_command = f"ask world {{ do set_agents_vel(matrix([{vt_str}]),matrix([{vr_str}])); }}"
            env.client.sync_expression(env.experiment_id, gama_command)

            gama_response = env.client.sync_expression(env.experiment_id, r"cycle")
            print("asking simulation the value of: cycle=", gama_response["content"])

            gama_response = env.client.sync_expression(env.experiment_id, r"ask world { do get_agents_pos(); }")
            print("asking simulation the value of: points=", gama_response["content"])
            step += 1
            await asyncio.sleep(2)

if __name__ == "__main__":
    asyncio.run(main())
