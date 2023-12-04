import asyncio
from typing import Dict
import numpy as np
import re
from gama_client.sync_client import GamaSyncClient
from gama_client.message_types import MessageTypes


async def async_command_answer_handler(message: Dict):
    # print("Here is the answer to an async command: ", message)
    pass


async def gama_server_message_handler(message: Dict):
    # print("I just received a message from Gama-server \and it's not an answer to a command!")
    # print("Here it is:", message)
    pass


# Definición de la clase GamaEnv
class GamaEnv:
    # Constructor de la clase
    def __init__(self):
        server_url = "localhost"  # URL del servidor
        server_port = 6868  # Puerto del servidor
        # Creación del cliente de Gama, especificando manejadores para comandos asíncronos y mensajes del servidor
        self.client = GamaSyncClient(server_url, server_port, async_command_answer_handler, gama_server_message_handler)

        self.experiment_id = ''  # ID del experimento, inicialmente vacío
        self.number_agents = 50  # Número de agentes en el experimento

    # Entrada asíncrona al gestor de contexto
    async def __aenter__(self):
        print("connecting to Gama server")
        await self.client.connect()  # Conexión al servidor GAMA
        return self

    # Salida asíncrona del gestor de contexto
    async def __aexit__(self, exc_type, exc_value, traceback):
        print("killing the simulation")
        gama_response = self.client.sync_stop(self.experiment_id)  # Detención del experimento
        # Verificación de la respuesta del servidor
        if gama_response["type"] != MessageTypes.CommandExecutedSuccessfully.value:
            print("Unable to stop the experiment", gama_response)
        print("closing socket just to be sure")
        self.client.sync_close_connection()  # Cierre de la conexión por seguridad

    # Carga del modelo GAML y configuración del experimento
    def load(self, gaml_file_path, exp_name, exp_parameters):
        print("initialize a gaml model")
        # Carga del modelo GAML y configuración de parámetros del experimento
        gama_response = self.client.sync_load(gaml_file_path, exp_name, True, True, True, True,
                                              parameters=exp_parameters)
        try:
            self.experiment_id = gama_response["content"]  # Asignación del ID del experimento
            print(f"experiment_id {self.experiment_id}")

            if gama_response["type"] != MessageTypes.CommandExecutedSuccessfully.value:
                print("error while trying to run the experiment", gama_response)
                print("initialization successful, running the model")
            else:
                print("Have run the experiment", gama_response)

        except Exception as e:
            print("error while initializing", gama_response, e)


# Función principal asíncrona
async def main():
    # Constantes del experimento y del servidor GAMA
    gaml_file_path = str("D:/Development/UNIVERSIDAD/SMA/sma.practica/P2_Robots_LevBerezhnoy.gaml")
    exp_name = "Robots_experimento"
    exp_parameters = [{"type": "int", "name": "number_agentes", "value": 50},
                      {"type": "bool", "name": "external_launch", "value": True}]

    # Uso del gestor de contexto para manejar el entorno GamaEnv
    async with GamaEnv() as env:
        env.load(gaml_file_path, exp_name, exp_parameters)
        step = 0
        while step < 10:
            # Creación de matrices para velocidades y rotaciones de los agentes
            matrix_vt = np.full((env.number_agents, 1), 2.0)
            matrix_vr = np.random.uniform(-50.0, 50.0, size=(env.number_agents, 1))

            # Conversión de matrices NumPy a cadenas para consulta GAMA
            vt_str = ','.join([str(v[0]) for v in matrix_vt])
            vr_str = ','.join([str(v[0]) for v in matrix_vr])

            # Formación de una cadena de consulta para GAMA
            gama_command = f"ask world {{ do set_agents_vel(matrix([{vt_str}]),matrix([{vr_str}])); }}"
            env.client.sync_expression(env.experiment_id, gama_command)

            env.client.sync_step(env.experiment_id)

            # Obtención y procesamiento de respuestas del servidor GAMA
            cycle_response = env.client.sync_expression(env.experiment_id, r"cycle")["content"]
            print("asking simulation the value of: cycle=", int(cycle_response))

            points_response = env.client.sync_expression(env.experiment_id, r"ask world { do get_agents_pos(); }")[
                "content"]
            matches = re.findall(r'\{x=([\d.\-]+), y=([\d.\-]+), d=([\d.\-]+)}', points_response)
            points_set = set((round(float(x), 2), round(float(y), 2), round(float(d), 2)) for x, y, d in matches)
            print("asking simulation the value of: points=", points_set)

            step += 1
            await asyncio.sleep(1)  # Pausa entre iteraciones


if __name__ == "__main__":
    asyncio.run(main())
