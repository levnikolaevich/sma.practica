/**
* Name: P1 Wumpus. ASM 23/24
* Author: Fidel
* Student: Lev Berezhnoy
* Tags: 
*/

model Wumpus_template


global {
    list<gworld> zonesOcupades <- [];  // Lista de zonas ocupadas
    
    predicate buscar_desire <- new_predicate("buscar");  // Predicado para la intención de buscar
    string glitterLocation <- "glitterLocation";  // Ubicación del brillo
    string dangerLocation <- "dangerLocation";  // Ubicación del peligro
        
    // Inicialización del modelo
    init {
        create goldArea number:1;  // Crear área de oro
        create wumpusArea number:1;  // Crear área de Wumpus
        create pozoArea number:5;  // Crear áreas de pozos
        create player number:2;  // Crear jugadores
    }
}

species player skills: [moving] control: simple_bdi{
    gworld place;  // Lugar actual
    gworld nextPaso;  // Próximo paso
    gworld pasoPasado;  // Paso anterior
    
    list<gworld> pasosPasados <- [];  // Lista de pasos pasados
    list<gworld> dangerZones <- [];  // Zonas peligrosas
    
    // Inicialización de la especie
    init {        
        place <- one_of(gworld - zonesOcupades);  // Elegir un lugar no ocupado
        location <- place.location;    // Establecer ubicación
        do add_desire(buscar_desire);  // Añadir deseo de buscar
    }
    
    // Percepción de área con brillo
    perceive target:glitterArea in: 0{ 
        focus id: glitterLocation var:location strength:10.0;  // Enfocar en la ubicación del brillo
        ask myself{
            do remove_intention(buscar_desire, true);  // Remover la intención de buscar
        } 
    }
    
    // Percepción de área con olor
    perceive target:odorArea in: 0{ 
        focus id: dangerLocation var:location strength:10.0;  // Enfocar en la ubicación del peligro
        ask myself{
            do remove_intention(buscar_desire, true);  // Remover la intención de buscar
        } 
    }
    
    // Percepción de área con brisa
    perceive target:brisaArea in: 0{ 
        focus id: dangerLocation var:location strength:10.0;  // Enfocar en la ubicación del peligro
        ask myself{
            do remove_intention(buscar_desire, true);  // Remover la intención de buscar
        } 
    }
    
    // Reglas para crear nuevas intenciones basadas en creencias
    rule belief: new_predicate(glitterLocation) new_desire: get_predicate(get_belief_with_name(glitterLocation));
    rule belief: new_predicate(dangerLocation) new_desire: get_predicate(get_belief_with_name(dangerLocation));

    // Plan para buscar
    plan buscar intention: buscar_desire priority:5{        
        speed <- 10.0;  // Velocidad
        list<gworld> vecinos <- [];        
        ask place {
            vecinos <- neighbors;  // Obtener vecinos
            color <- #white;  // Cambiar color
        }
        nextPaso <-  one_of(vecinos - pasosPasados - dangerZones);  // Elegir próximo paso
        if(nextPaso = nil)
        {
            nextPaso <-  one_of(vecinos - dangerZones);  // Elegir alternativa si no hay próximo paso
        }
        pasosPasados <- pasosPasados + place;  // Actualizar pasos pasados
        place <- nextPaso;  // Actualizar lugar
        location <- place.location;    
        do goto(target: nextPaso);  // Ir al siguiente paso          
    }
    
    // Plan para recoger oro
    plan get_gold intention: new_predicate(glitterLocation) priority:1{        
        speed <- 10.0;  // Velocidad
        list<gworld> vecinos <- [];
        ask place {
            vecinos <- neighbors;  // Obtener vecinos
        }
        
        pasoPasado <- place;  // Guardar paso pasado
        bool isGetGold <- true;  // Bandera para obtener oro
        
        ask goldArea
        {
            if(location = myself.location){
                ask world{
                    do pause;  // Pausar si se encuentra el oro
                } 
            }
            else
            {
                isGetGold <- false;  // Cambiar bandera si no se encuentra el oro
            }
        }
        
        if(!isGetGold)
        {
            isGetGold <- true;
            do goto(target: pasoPasado);  // Regresar al paso pasado
            place <- pasoPasado;  // Actualizar lugar
            nextPaso <- one_of(vecinos - pasosPasados - dangerZones);  // Elegir próximo paso
            do goto(target: nextPaso);  // Ir al siguiente paso           
        }        
    }
    
    // Plan para escapar del peligro
    plan escape intention: new_predicate(dangerLocation) priority:1{        
        speed <- 10.0;  // Velocidad
        dangerZones <- dangerZones + place;  // Añadir zona peligrosa
        gworld lastPaso <- pasosPasados[length(pasosPasados) - 1];  // Obtener último paso
        place <- lastPaso;  // Actualizar lugar
        location <- place.location;
        do goto(target: lastPaso);  // Ir al último paso
        do remove_belief(get_predicate(get_current_intention()));  // Remover creencia
        do remove_intention(get_predicate(get_current_intention()), true);  // Remover intención
        do add_desire(buscar_desire,5.0);  // Añadir deseo de buscar             
    }
    
    // Aspecto visual de los jugadores
    aspect base {
      draw circle(2) color: #magenta border: #black;        
    }
}

grid gworld width: 25 height: 25 neighbors:4 {
    rgb color <- #green;  // Color de la cuadrícula
}

// Definiciones de las diferentes especies y sus aspectos visuales
species odorArea{
    aspect base {
      draw square(4) color: #brown border: #black;        
    }
}

species wumpusArea{
    // Inicialización de la especie Wumpus
    init {
        gworld place <- one_of(gworld - zonesOcupades);  // Elegir lugar no ocupado
        location <- place.location;
        
        zonesOcupades <- zonesOcupades + place;  // Añadir a zonas ocupadas
        
        list<gworld> vecinos <- [];
        ask place {
            vecinos <- neighbors;  // Obtener vecinos
        }
        
        loop i over: vecinos {
            create odorArea{
                location <- i.location;  // Crear área con olor
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
    // Inicialización de la especie de área dorada
    init {
        gworld place <- one_of(gworld - zonesOcupades);  // Elegir lugar no ocupado
        location <- place.location;
        
        zonesOcupades <- zonesOcupades + place;  // Añadir a zonas ocupadas
        
        list<gworld> vecinos <- [];
        ask place {
            vecinos <- neighbors;  // Obtener vecinos
        }
        
        loop i over: vecinos {
            create glitterArea{
                location <- i.location;  // Crear área con brillo
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
    // Inicialización de la especie de pozos
    init {                        
        gworld place <- one_of(gworld - zonesOcupades);  // Elegir lugar no ocupado
        location <- place.location;
        zonesOcupades <- zonesOcupades + place;  // Añadir a zonas ocupadas

        list<gworld> vecinos <- [];
        ask place {
            vecinos <- neighbors;  // Obtener vecinos
        }
        
        loop i over: vecinos {
            create brisaArea{
                location <- i.location;  // Crear área con brisa
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