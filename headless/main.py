import asyncio
from typing import Dict
import numpy as np
import gym
from gama_client.sync_client import GamaSyncClient
from gama_client.message_types import MessageTypes


async def async_command_answer_handler(message: Dict):
    print("Here is the answer to an async command: ", message)


async def gama_server_message_handler(message: Dict):
    print("I just received a message from Gama-server and it's not an answer to a command!")
    print("Here it is:", message)


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

    def reset(self):
        # Сброс среды
        self.client.sync_expression(self.experiment_id, "do restart;")
        obs = self.client.sync_expression(self.experiment_id, "ask world { do get_agents_pos(); }")["content"]
        return np.array(obs)

    def compute_reward(self, obs):
        # Вычисление вознаграждения на основе текущего состояния
        # Например, штраф за столкновения
        reward = 0
        # ... вычисление вознаграждения ...
        return reward

    def is_done(self, obs):
        # Определение условия завершения эпизода
        # Например, все агенты столкнулись
        done = False
        # ... проверка условия ...
        return done


async def main():
    # Experiment and Gama-server constants
    gaml_file_path = str("D:/Development/UNIVERSIDAD/SMA/sma.practica/P2_Robots_LevBerezhnoy.gaml")
    exp_name = "Robots_experimento"
    exp_parameters = [{"type": "int", "name": "number_agentes", "value": 55}]

    async with GamaGymEnv() as env:
        env.run(gaml_file_path, exp_name, exp_parameters)

        step = 0
        while step < 10:
            gama_response = env.client.sync_expression(env.experiment_id, r"cycle")
            print("asking simulation the value of: cycle=", gama_response["content"])

            gama_response = env.client.sync_expression(env.experiment_id, r"ask world { do get_agents_pos(); }")
            print("asking simulation the value of: cycle=", gama_response["content"])
            step += 1
            await asyncio.sleep(2)

    # Пример использования среды
    # obs = env.reset()
    # for _ in range(1000):  # Ограничим количество шагов для примера
    # action = env.action_space.sample()  # Случайные действия для примера
    # obs, reward, done, _ = env.step(action)
    # if done:
    # break


if __name__ == "__main__":
    asyncio.run(main())
