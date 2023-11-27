/**
* Name: Plantilla P1 Wumpus. ASM 23/24
* Author: Fidel
* Student: Lev Berezhnoy
* Tags: 
*/

model Wumpus_template

global {
	
	int steps;
	int number_agentes <- 50;
	int number_live_agentes <- 50;	
	float agent_size <- 0.5;
	
	matrix<float> vt <- rnd(0.5,2.5) as_matrix({1,number_agentes});
	matrix<float> vr <- rnd(-50.0,50.0) as_matrix({1,number_agentes});
	
	init {
		create ag_wander number: number_agentes;
		number_live_agentes <- number_agentes;		
		steps <- 0;
	}
	
	
	reflex {
		steps <- steps + 1;
		
		//write "---------------------------";
		do get_agents_pos();
		
		number_live_agentes <- length(list<ag_wander> (ag_wander where (each.color=#red)));
		matrix<float> matrix_vt <- rnd(0.5,2.5) as_matrix({1,number_live_agentes});
		matrix<float> matrix_vr <- rnd(-50.0,50.0) as_matrix({1,number_live_agentes});
		//write matrix_vt;
		do set_agents_vel(matrix_vt, matrix_vr);
	}
	
	reflex stop_game when: steps = 5000{
		do pause;
	}
	
	reflex stop_game2 when: ag_wander all_match (each.color=#black) {
		do pause;
	}
	
	list<point>	get_agents_pos{
		list<point> points;	
		
		ask agents of_species ag_wander {
			//write self.location;
    		points <- points + self.location;
		}	
		return points;
	}
	
	action set_agents_vel(matrix<float> vt_loc, matrix<float> vr_loc){
		matrix speed_matrix <- 0.0 as_matrix({1,length(agents of_species ag_wander)}); 
		
		write "---------------------------";		
		ask agents of_species ag_wander {
			//speed_matrix <- matrix(speed) + vt_loc;
			//write self.location;
			//write "speed " + speed;
			//write "heading " + heading;
    		//speed <- speed + vt_loc;
    		//speed <- speed + vr_loc;
		}	
		write speed_matrix;
	}
	
	action restart {
		steps <- 0;
		
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
	
	point get_closest_neighbourd_pos {
		return agent_closest_to(self).location;
	}
	
	reflex do_move
	{	
		if(self.color != #black){
			speed <- rnd(0.5,2.5);
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