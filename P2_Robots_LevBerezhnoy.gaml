/**
* Name: P2 Robots. ASM 23/24
* Author: Fidel
* Student: Lev Berezhnoy
* Tags: 
*/

model Robots_template

global {
	
	int current_steps;
	int limit_steps  <- 10;
	int number_agentes <- 50;

	float agent_size <- 0.5;
	
	matrix<float> vt <- rnd(0.5,2.5) as_matrix({1,number_agentes});
	matrix<float> vr <- rnd(-50.0,50.0) as_matrix({1,number_agentes});
	
	init {
		create ag_wander number: number_agentes;
		current_steps <- 0;
	}
	
	
	reflex {
		current_steps <- current_steps + 1;
		
		do get_agents_pos();
		
		matrix<float> matrix_vt <- list_with(number_agentes,2.0) as matrix;
		matrix<float> matrix_vr <- list_with(number_agentes,rnd(-50.0,50.0)) as matrix;
		
		//COMENTAR la línea cuando se trabaja con PYTHON
		do set_agents_vel(matrix_vt, matrix_vr);
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
	
	action set_velocity(float vt_, float vr_){
		do move speed: vt_ heading: vr_;
	}
	
	float get_dist_a_closest_neighbourd {
		point neighbourd_point <- agent_closest_to(self).location;
		float distance <- sqrt(abs(neighbourd_point.location.x-self.location.x) ^ 2 + abs(neighbourd_point.location.y-self.location.y) ^ 2);
		return distance;
	}
	
	reflex do_move
	{	
		if(self.color != #black){
			speed <- rnd(1.5,2.5);
			angulo <- angulo + rnd(-50,50);
			//do set_velocity(speed, angulo);
		}
	}
	
	reflex collision {
		list<ag_wander> col <- list<ag_wander>(agents at_distance(agent_size));
		
		ask col {
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
	}
}