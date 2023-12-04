/**
* Name: P2 Robots. ASM 23/24
* Author: Fidel
* Student: Lev Berezhnoy
* Tags: 
*/

model Robots_template

global {
	
	int current_steps;
	int limit_steps  <- 5000;
	int number_agentes <- 50;

	float agent_size <- 0.5;
	
	float avoidance_distance <- 3.0;
	int collisions <- 0;
	bool external_launch <- false;
	bool batch_experiment <- true; //establecer 'true' antes de ejecutar el experimento 'avoidance_distance_optimization'
	
	init {
		create ag_wander number: number_agentes;
		current_steps <- 0;
		collisions <- 0;
	}	

	reflex {
		current_steps <- current_steps + 1;
		
		if(not batch_experiment and not external_launch){
			//write get_agents_pos();
						
			matrix<float> matrix_vt <- list_with(number_agentes,2.0) as matrix;
			matrix<float> matrix_vr <- list_with(number_agentes,rnd(-50.0,50.0)) as matrix;
			do set_agents_vel(matrix_vt, matrix_vr);
		}		
	}
	
	reflex stop_game when: current_steps = limit_steps {
		do pause;
	}
	
	reflex stop_game2 when: ag_wander all_match (each.color=#black) {
		do pause;
	}
	
	list<map> get_agents_pos{
		list<map> points;
		ask agents of_species ag_wander {
        	float distance <- self.get_dist_a_closest_neighbourd();
    		points <- points + list([map('x':: self.location.x, 'y':: self.location.y, 'd':: distance)]);
		}	
		return points;
	}
	
	action set_agents_vel(matrix<float> vt_matrix, matrix<float> vr_matrix){
		ask agents of_species ag_wander 
		{	
			if(self.color != #black){	
				do set_velocity(vt_matrix column_at (agents index_of self) at 0, self.heading + vr_matrix column_at (agents index_of self) at 0);
			}
		}
	}
	
	action restart {
		current_steps <- 0;
		
		ask ag_wander
		{
			do die;			
		}
		
		create ag_wander number: number_agentes;
	}
}

species ag_wander skills: [moving] {	
	float angulo <- 0.0;
	float speed <- 2.0;
	rgb color <- #red;
	
	action set_velocity(float vt, float vr){
		do move speed: vt heading: vr;
	}
	
	float get_dist_a_closest_neighbourd {
		point neighbourd_point <- agent_closest_to(self).location;
		float distance <- sqrt(abs(neighbourd_point.location.x-self.location.x) ^ 2 + abs(neighbourd_point.location.y-self.location.y) ^ 2);
		return distance;
	}
	
	reflex do_move
	{	
		if(batch_experiment and not external_launch){
			if(self.color != #black){
				float distance <- get_dist_a_closest_neighbourd();
				speed <- 2.0;
				
				if(distance < avoidance_distance){
					angulo <- angulo + rnd(-90,90);
				} else {
					angulo <- angulo + rnd(-50,50);
				}
				do set_velocity(speed, angulo);
			}
		}			
	}
	
	reflex collision {
		list<ag_wander> col <- list<ag_wander>(agents at_distance(agent_size));
		
		ask col {
			collisions <- collisions + 1;
			self.color <- #black;
		}
	}
	
	aspect base {
	  draw circle(agent_size) color: color;		
	}
}

grid gworld width: 35 height: 35 neighbors:8 {
	rgb color <- #white;
}


experiment Robots_experimento type: gui {
	/** Insert here the definition of the input and output of the model */
	float minimum_cycle_duration <- 0.05;
	
	output {					
		display view1 { 
			grid gworld border: #white;
			species ag_wander aspect:base;
		}
		display "robots_stats"  type: 2d {
			// display some statistics about the robots
			chart "number robots" type:series position:{0.0,0.0} size:{0.5,0.5} {
				data "Lived" value: length(ag_wander where (each.color=#red)) color:#red;
				data "Died" value: length(ag_wander where (each.color=#black)) color:#black;
			}			
		}
	}
}

experiment avoidance_distance_optimization type: batch until: ag_wander all_match (each.color=#black) or current_steps = limit_steps repeat:10 {
    parameter 'avoidance_distance:' var: avoidance_distance min: 0.5 max: 5.0 step: 0.5;

    method genetic 
        minimize: collisions
        pop_dim: 20 crossover_prob: 0.7 mutation_prob: 0.1 
        nb_prelim_gen: 2 max_gen: 20; 
	
	output {					
		display "robots_stats"  type: 2d {
			// display some statistics about the robots
			chart "number robots" type:series position:{0.0,0.0} size:{0.5,0.5} {
				data "Lived" value: length(ag_wander where (each.color=#red)) color:#red;
				data "Died" value: length(ag_wander where (each.color=#black)) color:#black;
			}			
		}
	}
}