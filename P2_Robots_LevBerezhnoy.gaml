/**
* Name: P2 Robots. ASM 23/24
* Author: Fidel
* Student: Lev Berezhnoy
* Tags: 
*/

model Robots_template

global {
    // Definiciones de variables globales
    int current_steps;  // Contador actual de pasos
    int limit_steps  <- 5000;  // Límite de pasos
    int number_agentes <- 50;  // Número de agentes

    float agent_size <- 0.5;  // Tamaño del agente
    
    float avoidance_distance <- 3.0;  // Distancia de evasión
    int collisions <- 0;  // Contador de colisiones
    bool external_launch <- false;  // Indicador de lanzamiento externo
    bool batch_experiment <- true;  // 'true' para ejecutar el experimento 'avoidance_distance_optimization'
    
    // Inicialización del modelo
    init {
        create ag_wander number: number_agentes;  // Crear agentes
        current_steps <- 0;  // Inicializar contador de pasos
        collisions <- 0;  // Reiniciar contador de colisiones
    }    

    // Reflejo para actualizar contador de pasos y ejecutar acciones
    reflex {
        current_steps <- current_steps + 1;
        
        if(not batch_experiment and not external_launch){
            matrix<float> matrix_vt <- list_with(number_agentes,2.0) as matrix;  // Matriz de velocidades lineales
            matrix<float> matrix_vr <- list_with(number_agentes,rnd(-50.0,50.0)) as matrix;  // Matriz de velocidades rotacionales
            do set_agents_vel(matrix_vt, matrix_vr);  // Establecer velocidades de los agentes
        }        
    }
    
    // Reflejo para detener el juego al alcanzar el límite de pasos
    reflex stop_game when: current_steps = limit_steps {
        do pause;  // Pausar la simulación
    }
    
    // Reflejo para detener el juego cuando todos los agentes sean de color negro
    reflex stop_game2 when: ag_wander all_match (each.color=#black) {
        do pause;  // Pausar la simulación
    }
    
    // Función para obtener posiciones de los agentes
    list<map> get_agents_pos{
        list<map> points;
        ask agents of_species ag_wander {
            float distance <- self.get_dist_a_closest_neighbourd();  // Distancia al vecino más cercano
            points <- points + list([map('x':: self.location.x, 'y':: self.location.y, 'd':: distance)]);  // Añadir punto a la lista
        }    
        return points;  // Retornar lista de puntos
    }
    
    // Acción para establecer velocidades de los agentes
    action set_agents_vel(matrix<float> vt_matrix, matrix<float> vr_matrix){
        ask agents of_species ag_wander 
        {    
            if(self.color != #black){    
                do set_velocity(vt_matrix column_at (agents index_of self) at 0, self.heading + vr_matrix column_at (agents index_of self) at 0);
            }
        }
    }
    
    // Acción para reiniciar la simulación
    action restart {
        current_steps <- 0;
        
        ask ag_wander
        {
            do die;            
        }
        
        create ag_wander number: number_agentes;  // Crear nuevos agentes
    }
}

// Definición de la especie ag_wander con habilidades de movimiento
species ag_wander skills: [moving] {    
    float angulo <- 0.0;  // Ángulo de giro
    float speed <- 2.0;  // Velocidad
    rgb color <- #red;  // Color inicial
    
    // Acción para establecer velocidad y dirección
    action set_velocity(float vt, float vr){
        do move speed: vt heading: vr;
    }
    
    // Función para obtener distancia al vecino más cercano
    float get_dist_a_closest_neighbourd {
        point neighbourd_point <- agent_closest_to(self).location;  // Punto del vecino más cercano
        float distance <- sqrt(abs(neighbourd_point.location.x-self.location.x) ^ 2 + abs(neighbourd_point.location.y-self.location.y) ^ 2);
        return distance;  // Retornar distancia
    }
    
    // Reflejo para movimiento de agentes
    reflex do_move
    {    
        if(batch_experiment and not external_launch){
            if(self.color != #black){
                float distance <- get_dist_a_closest_neighbourd();  // Obtener distancia al vecino más cercano
                speed <- 2.0;  // Establecer velocidad
                
                if(distance < avoidance_distance){
                    angulo <- angulo + rnd(-90,90);  // Cambiar ángulo si distancia es menor que la de evasión
                } else {
                    angulo <- angulo + rnd(-50,50);  // Cambiar ángulo aleatoriamente
                }
                do set_velocity(speed, angulo);  // Establecer velocidad y dirección
            }
        }            
    }
    
    // Reflejo para detectar colisiones
    reflex collision {
        list<ag_wander> col <- list<ag_wander>(agents at_distance(agent_size));
        
        ask col {
            collisions <- collisions + 1;  // Incrementar contador de colisiones
            self.color <- #black;  // Cambiar color del agente
        }
    }
    
    // Aspecto para dibujar agentes
    aspect base {
      draw circle(agent_size) color: color;        
    }
}

// Definición de la cuadrícula del mundo
grid gworld width: 35 height: 35 neighbors:8 {
    rgb color <- #white;
}

// Experimento de interfaz gráfica
experiment Robots_experimento type: gui {
    /** Inserte aquí la definición de entradas y salidas del modelo */
    float minimum_cycle_duration <- 0.05;
    
    output {                    
        display view1 { 
            grid gworld border: #white;
            species ag_wander aspect:base;  // Mostrar agentes
        }
        display "robots_stats"  type: 2d {
            // Mostrar estadísticas sobre los robots
            chart "number robots" type:series position:{0.0,0.0} size:{0.5,0.5} {
                data "Lived" value: length(ag_wander where (each.color=#red)) color:#red;
                data "Died" value: length(ag_wander where (each.color=#black)) color:#black;
            }            
        }
    }
}

// Experimento de tipo batch para optimización
experiment avoidance_distance_optimization type: batch until: ag_wander all_match (each.color=#black) or current_steps = limit_steps repeat:10 {
    parameter 'avoidance_distance:' var: avoidance_distance min: 0.5 max: 5.0 step: 0.5;  // Parámetro de distancia de evasión

    method genetic 
        minimize: collisions  // Minimizar colisiones
        pop_dim: 20 crossover_prob: 0.7 mutation_prob: 0.1 
        nb_prelim_gen: 2 max_gen: 20;  // Configuración del algoritmo genético
    
    output {                    
        display "robots_stats"  type: 2d {
            // Mostrar estadísticas sobre los robots
            chart "number robots" type:series position:{0.0,0.0} size:{0.5,0.5} {
                data "Lived" value: length(ag_wander where (each.color=#red)) color:#red;
                data "Died" value: length(ag_wander where (each.color=#black)) color:#black;
            }            
        }
    }   
}