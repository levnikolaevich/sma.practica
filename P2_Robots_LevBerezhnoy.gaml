/**
* Name: Plantilla P1 Wumpus. ASM 23/24
* Author: Fidel
* Student: Lev Berezhnoy
* Tags: 
*/

model Wumpus_template

global {
	init {
		create ag_wander number:50;
	}
}

species ag_wander skills: [moving] {	
	float angulo <- 0.0;
	
	action set_velocity(float vt, float vr){
		do move speed: vt heading: vr;
	}
	
	reflex do_move
	{	
		angulo <- angulo + rnd(-50,50);

		do set_velocity(2, angulo);
	}
	
	aspect base {
	  draw circle(0.5) color: #red border: #red;		
	}
}

grid gworld width: 35 height: 35 neighbors:8 {
	rgb color <- #white;
}


experiment Robots_experimento type: gui {
	/** Insert here the definition of the input and output of the model */
	float minimum_cycle_duration <- 0.5;
	
	output {					
		display view1 { 
			grid gworld border: #white;
			species ag_wander aspect:base;
		}
	}
}