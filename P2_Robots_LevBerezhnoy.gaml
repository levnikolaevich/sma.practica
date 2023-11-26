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
	float agent_size <- 0.5;
	
	init {
		create ag_wander number: number_agentes;		
		steps <- 0;
	}
	
	reflex {
		steps <- steps + 1;
	}
	
	reflex stop_game when: steps = 5000{
		do pause;
	}
	
	reflex stop_game2 when: ag_wander all_match (each.color=#black) {
		do pause;
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
			angulo <- angulo + rnd(-50,50);
			do set_velocity(2.0, angulo);
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