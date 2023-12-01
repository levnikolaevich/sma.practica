/**
* Name: P1 Wumpus. ASM 23/24
* Author: Fidel
* Student: Lev Berezhnoy
* Tags: 
*/

model Wumpus_template

global {
	list<gworld> zonesOcupades <- [];
	
	predicate buscar_desire <- new_predicate("buscar");
	string glitterLocation <- "glitterLocation";
	string dangerLocation <- "dangerLocation";
		
	init {
		create goldArea number:1;
		create wumpusArea number:1;
		create pozoArea number:5;
		create player number:2;
	}
}

species player skills: [moving] control: simple_bdi{
	gworld place;
	gworld nextPaso;
	gworld pasoPasado;
	
	list<gworld> pasosPasados <- [];
	list<gworld> dangerZones <- [];
	
	init {		
		place <- one_of(gworld - zonesOcupades);
		location <- place.location;	
		do add_desire(buscar_desire);
	}
	
	perceive target:glitterArea in: 0{ 
		focus id: glitterLocation var:location strength:10.0; 
		ask myself{
			do remove_intention(buscar_desire, true);
		} 
	}
	
	perceive target:odorArea in: 0{ 
		focus id: dangerLocation var:location strength:10.0; 
		ask myself{
			do remove_intention(buscar_desire, true);
		} 
	}
	
	perceive target:brisaArea in: 0{ 
		focus id: dangerLocation var:location strength:10.0; 
		ask myself{
			do remove_intention(buscar_desire, true);
		} 
	}
	
	rule belief: new_predicate(glitterLocation) new_desire: get_predicate(get_belief_with_name(glitterLocation));
	rule belief: new_predicate(dangerLocation) new_desire: get_predicate(get_belief_with_name(dangerLocation));

	plan buscar intention: buscar_desire priority:5{		
		speed <- 10.0;
		list<gworld> vecinos <- [];		
		ask place {
			vecinos <- neighbors;
			color <- #white; 
		}
		nextPaso <-  one_of(vecinos - pasosPasados - dangerZones);
		if(nextPaso = nil)
		{
			nextPaso <-  one_of(vecinos - dangerZones);
		}
		pasosPasados <- pasosPasados + place;
		place <- nextPaso;
		location <- place.location;	
		do goto(target: nextPaso);			
	}
	
	plan get_gold intention: new_predicate(glitterLocation) priority:1{		
		speed <- 10.0;
		list<gworld> vecinos <- [];
		ask place {
			vecinos <- neighbors;
		}
		
		pasoPasado <- place;
		bool isGetGold <- true;
		
		ask goldArea
		{
			if(location = myself.location){
				ask world{
					do pause;
				} 
			}
			else
			{
				isGetGold <- false;
			}
		}
		
		if(!isGetGold)
		{
			isGetGold <- true;
			do goto(target: pasoPasado);
			place <- pasoPasado;
			nextPaso <- one_of(vecinos - pasosPasados - dangerZones);
			do goto(target: nextPaso);			
		}		
	}
	
	plan escape intention: new_predicate(dangerLocation) priority:1{		
		speed <- 10.0;	
		dangerZones <- dangerZones + place;
		gworld lastPaso <- pasosPasados[length(pasosPasados) - 1];
		place <- lastPaso;
		location <- place.location;
		do goto(target: lastPaso);
		do remove_belief(get_predicate(get_current_intention()));
		do remove_intention(get_predicate(get_current_intention()), true);
		do add_desire(buscar_desire,5.0);				
	}
	
	aspect base {
	  draw circle(2) color: #magenta border: #black;		
	}
}

grid gworld width: 25 height: 25 neighbors:4 {
	rgb color <- #green;
}



species odorArea{
	aspect base {
	  draw square(4) color: #brown border: #black;		
	}
}


species wumpusArea{
	init {
		gworld place <- one_of(gworld - zonesOcupades);
		location <- place.location;
		
		zonesOcupades <- zonesOcupades + place;
		
		//Place es un cell, y por tanto puedo solicitar sus vecinos https://gama-platform.org/wiki/GridSpecies
		list<gworld> vecinos <- [];
		ask place {
			vecinos <- neighbors;
		}
		
		loop i over: vecinos {
			create odorArea{
				location <- i.location;
			}
		}
	}
	aspect base {
	  draw square(4) color: #red border: #black;		
	}
}

species glitterArea{
	aspect base {
	  draw square(4) color: #chartreuse border: #black;		
	}
}

species goldArea{
	init {
		gworld place <- one_of(gworld - zonesOcupades);
		location <- place.location;
		
		zonesOcupades <- zonesOcupades + place;
		
		//Place es un cell, y por tanto puedo solicitar sus vecinos https://gama-platform.org/wiki/GridSpecies
		list<gworld> vecinos <- [];
		ask place {
			vecinos <- neighbors;
		}
		
		loop i over: vecinos {
			create glitterArea{
				location <- i.location;
			}
		}
	
	}
	
	aspect base {
	  draw square(4) color: #yellow border: #black;		
	}
}

species brisaArea{
	aspect base {
	  draw square(4) color: #blue border: #black;		
	}
}

species pozoArea{
	init {						
		gworld place <- one_of(gworld - zonesOcupades);
		location <- place.location;
		zonesOcupades <- zonesOcupades + place;

		//Place es un cell, y por tanto puedo solicitar sus vecinos https://gama-platform.org/wiki/GridSpecies
		list<gworld> vecinos <- [];
		ask place {
			vecinos <- neighbors;
		}
		
		loop i over: vecinos {
			create brisaArea{
				location <- i.location;
			}
		}	
	}
	
	aspect base {
	  draw square(4) color: #black border: #black;		
	}
}

experiment Wumpus_experimento_1 type: gui {
	/** Insert here the definition of the input and output of the model */
	float minimum_cycle_duration <- 0.5;
	
	output {					
		display view1 { 
			grid gworld border: #darkgreen;
			species goldArea aspect:base;
			species glitterArea aspect:base;
			species wumpusArea aspect:base;
			species odorArea aspect:base;
			species brisaArea aspect:base;
			species pozoArea aspect:base;
			species player aspect:base;
		}
	}
}