/**
* Name: Mercado Financero
* Authors: 
* Tags: gaml, gama, mercado_financero, the_university_of_Alicante
*/

model abp

global {
	bool isDebug <- false;
		
	int identifier <- 0;
	
	int time_to_recalculate_expectation_price <- 30; //cycles
	
	// investor count
	int hr_investor_count <- 20 min: -1 parameter: 'Number of aggressive investors:' category: 'Investors';
    int mr_investor_count <- 10 min: -1  parameter: 'Number of moderate investors:' category: 'Investors';
	int lr_investor_count <- 11 min: -1  parameter: 'Number of conservative investors:' category: 'Investors';
	int house_count <- 10 min: 0 parameter: 'Number of houses:' category: 'Investors'; 
	float part_to_spend <- 0.20 min: 0.0 max: 1.0 parameter: 'Part of budget to spend to buy shares:' category: 'Investors';     //de budget de investor en porcentaje para hacer una compra
	int investor_total_count; 
	float panic_price_decline <- 0.07 min: 0.0 max: 1.0 parameter: 'Panic selling threshold level:' category: 'Investors'; // decline of price when investor wants to sell	
	float share_of_remaining_capital <- 0.5 min: 0.0 max: 1.0 parameter: 'Share of remaining capital:' category: 'Investors'; // the share of lost capital after which we kill the investor
	
	// share count
	float share_initial_price <- 100.0 min: 0.0 parameter: 'Share\'s initial price:' category: 'Shares'; 
	float energetic_sector_share_risk <- rnd(0.1,0.2) with_precision 2 min: 0.0 max: 1.0 parameter: 'Energetic share risk:' category: 'Shares';
	float tech_sector_share_risk <- rnd(0.06,0.1) with_precision 2 min: 0.0 max: 1.0 parameter: 'Tech share risk:' category: 'Shares';
	float food_sector_share_risk <- rnd(0.02,0.05) with_precision 2 min: 0.0 max: 1.0 parameter: 'Food share risk:' category: 'Shares';
	
	// Display
	float energetic_sector_value;
	float tech_sector_value;
	float food_sector_value;
	int energetic_sector_shares_count;
	int tech_sector_shares_count;
	int food_sector_shares_count;
	
	float energetic_sector_share_price;
	float tech_sector_share_price;
	float food_sector_share_price;
	
	predicate house_desire <- new_predicate("house");
	predicate sector_desire <- new_predicate("sector");
	predicate high_risk_shares_desire <- new_predicate("highRiskShares"); 		/* ENERGETIC */
	predicate medium_risk_shares_desire <- new_predicate("mediumRiskShares");	/* TECH */
	predicate low_risk_shares_desire <- new_predicate("lowRiskShares");			/* FOOD */
	predicate comprar_shares_desire <- new_predicate("comprarShares");
	predicate vender_shares_desire <- new_predicate("venderShares");
	
	string houseLocation <- "houseLocation";
	string sectorLocation <- "sectorLocation";
	string highRiskLocation <- "highRiskLocation";								/* ENERGETIC */
	string mediumRiskLocation <- "mediumRiskLocation";							/* TECH */
	string lowRiskLocation <- "lowRiskLocation";								/* FOOD */
	
	int count_of_buying <- 0;
	int count_of_selling <- 0;
	
	list<map> good_strategies <- [];
	list<map> bad_strategies <- [];
	
	int current_time;
	
		
	init {		
		create energetic_sector number: 1;
		create tech_sector number: 1;
		create food_sector number: 1;
		create house number: house_count;
		
		investor_total_count <- house_count * (hr_investor_count +  mr_investor_count + lr_investor_count); 
		hr_investor_count <- house_count * hr_investor_count;
		mr_investor_count <- house_count * mr_investor_count;
		lr_investor_count <- house_count * lr_investor_count;
		
		energetic_sector_value <-0.0;
		tech_sector_value <-0.0;
		food_sector_value <-0.0;
		
		current_time <- #now as int;
	}
	
	reflex next_step {
		step <- step + 1.0;
	}
	
	reflex check_strategies when: step mod 100 = 0 {
		good_strategies <- [];
		map most_rich_person <- map('change':: 0.0);
		list<map> sector_overview;
		
		ask agents of_species energetic_sector 
		{	
			sector_overview <- sector_overview + list([map('sector_type'::'energetic', 'price':: self.current_share_price with_precision 2, 'risk':: self.share_risk)]);
		}
		
		ask agents of_species tech_sector 
		{	
			sector_overview <- sector_overview + list([map('sector_type'::'tech', 'price':: self.current_share_price with_precision 2, 'risk':: self.share_risk)]);
		}
		
		ask agents of_species food_sector 
		{	
			sector_overview <- sector_overview + list([map('sector_type'::'food', 'price':: self.current_share_price with_precision 2, 'risk':: self.share_risk)]);
		}
		
		ask agents of_species aggressive_investor 
		{	
			good_strategies <- good_strategies + list([map('type'::'good', 'id':: self.id_investor, 'hr':: self.portion_high_risk, 'mr':: self.portion_medium_risk, 'lr':: self.portion_low_risk, 'init_money':: self.initial_money with_precision 2, 'money':: self.total_value with_precision 2, 'profit':: (self.total_value / self.initial_money) with_precision 2 )]);	
			do save_strategy_to_file('good'); 	
			if(self.total_value / self.initial_money > most_rich_person['change'])
			{
				most_rich_person <- map('id':: self.id_investor, 'change':: (self.total_value / self.initial_money) with_precision 2, 'money':: self.total_value with_precision 2, 'type':: 1);
			}
		}
		
		ask agents of_species moderate_investor 
		{	
			good_strategies <- good_strategies + list([map('type'::'good', 'id':: self.id_investor, 'hr':: self.portion_high_risk, 'mr':: self.portion_medium_risk, 'lr':: self.portion_low_risk, 'init_money':: self.initial_money with_precision 2, 'money':: self.total_value with_precision 2, 'profit':: (self.total_value / self.initial_money) with_precision 2 )]);	
			do save_strategy_to_file('good'); 	
			if(self.total_value / self.initial_money > most_rich_person['change'])
			{
				most_rich_person <- map('id':: self.id_investor, 'change':: (self.total_value / self.initial_money) with_precision 2, 'money':: self.total_value with_precision 2, 'type':: 2);
			}
		}
		
		ask agents of_species conservative_investor 
		{	
			good_strategies <- good_strategies + list([map('type'::'good', 'id':: self.id_investor, 'hr':: self.portion_high_risk, 'mr':: self.portion_medium_risk, 'lr':: self.portion_low_risk, 'init_money':: self.initial_money with_precision 2, 'money':: self.total_value with_precision 2, 'profit':: (self.total_value / self.initial_money) with_precision 2 )]);
			do save_strategy_to_file('good'); 	
			if(self.total_value / self.initial_money > most_rich_person['change'])
			{
				most_rich_person <- map('id':: self.id_investor, 'change':: (self.total_value / self.initial_money) with_precision 2, 'money':: self.total_value with_precision 2, 'type':: 3);
			}
		}
		write "---Most rich person, cycle №" + step + " : ";
		write "ID " + most_rich_person['id'] + ", money: " + most_rich_person['money'] + " euro, " + most_rich_person['change'] * 100 + "%, type - " + most_rich_person['type'];
		write "Sector overview: " + sector_overview;
		save [step,"Sector_overview: " + sector_overview,"Rich: " + most_rich_person] rewrite: false to: "experiment_overview_" + current_time + ".csv" format: csv;
	}
}

grid gworld width: 50 height: 50 neighbors: 8 {
	rgb color <- #white;
}

species house{
	init {
		gworld place <- one_of(gworld);
		location <- place.location;
		
		create aggressive_investor number: hr_investor_count {
			location <- place.location;
			house_location <- place.location;
		}
		create moderate_investor number: mr_investor_count {
			location <- place.location;
			house_location <- place.location;
		}
		create conservative_investor number: lr_investor_count {
			location <- place.location;
			house_location <- place.location;	
		}		
	}	
	aspect base {
	  draw file("../images/casa.png") size: 7;
	}
}


species sector{
	gworld place;	
	string sector_name;
	
	int shares_issued;
	float total_sector_value;
	
	string riskType; // H, M, L 
	
	float current_share_price;
	float share_risk;
	
	init{
		place <- one_of(gworld);
		location <- place.location;
	}
	
	action set_share_price(float price) 
	{
		current_share_price <- price;
	}
	
	action set_share_risk(float risk) 
	{
		share_risk <- risk;
	}
	
	action get_sector_name 
	{
		return sector_name;
	}

	//El método que utiliza el inversor para comprar acciones. 
	//El sector "emite" acciones por el monto asignado para la compra de las mismas.	
	list<share_batch> sell_shares_to_me(float invest) 
	{	
		if(isDebug){write "------------------BUY-----------------------";} //LOGS
		count_of_buying <- count_of_buying + 1;	
		if(isDebug){write "Sector_name: " + sector_name + "| buying №" + count_of_buying;}  //LOGS
		if(isDebug){write "new share_risk: " + share_risk;}  //LOGS

		list<share_batch> new_shares <- [];	
	
		int count <- invest / current_share_price as int;
		
		if (count < 1)
		{
			return [];
		}

		shares_issued <- shares_issued + count;
		total_sector_value <- shares_issued * current_share_price;
		
		float exp_price	<- current_share_price * (1 + share_risk);
		if(isDebug){write "new exp_price: " + exp_price;}  //LOGS

		create share_batch
		{				
			purchase_price <- myself.current_share_price;	
			last_price <- myself.current_share_price;					
			risk <- myself.share_risk;
			expectation_price <- exp_price;
			self.share_sector <- myself;
			count_of <- count;	
			 	
			ask myself
			{
				new_shares <- new_shares + [myself];
			}			
		}
		
		//Después de la compra de acciones, el precio de las mismas aumenta, lo que refleja la reacción del precio a la demanda.
		current_share_price <- current_share_price + 0.1*log(1 + count * abs(current_share_price - exp_price));
		if(isDebug){write "new current_share_price: " + current_share_price;} //LOGS
		
		return new_shares;
	}
	
	//El método que utiliza el inversor para vender acciones. 
	//El agente intenta vender las acciones si cree que su precio caerá.
	float buy_my_shares(list<share_batch> shares_for_selling) 
	{
		if(isDebug){write "------------------SELL-----------------------";} //LOGS
		count_of_selling <- count_of_selling + 1;	
		if(isDebug){write "Sector_name: " + sector_name + "| selling №" + count_of_selling;}  //LOGS
		float exp_price <- (shares_for_selling at 0).expectation_price;
		if(isDebug){write "current exp_price: " + exp_price;}  //LOGS
		
		int total_count  <- shares_for_selling sum_of (each.count_of);
		
		//Después de la venta, el precio de las acciones disminuye, lo que refleja la reacción del precio a la falta de demanda. 
		//La fórmula reduce el precio_actual_accion por un valor que depende del logaritmo de (1 más el producto de la cuenta_total 
		//y el valor absoluto de la diferencia entre el precio_actual_accion y el precio_esperado). 
		//Esto significa que el nuevo precio disminuye en respuesta a la cantidad de acciones vendidas 
		//y la diferencia entre el precio actual y el precio esperado. 
		//Cuanto mayor sea esta diferencia y la cantidad de acciones vendidas, mayor será la reducción en el precio de la acción.
		float new_price <- current_share_price - log(1 + total_count * abs(current_share_price - exp_price));
		current_share_price <- new_price < 1 ? 1 : new_price ;
						
		if(isDebug){write "new current_share_price: " + current_share_price;}  //LOGS
		
		shares_issued <- shares_issued - total_count;
		float income <- total_count * current_share_price;
		total_sector_value <- shares_issued * current_share_price;	
		return income;
	}
}

species energetic_sector parent:sector{
	init{
		energetic_sector_share_price <- share_initial_price;
		identifier <- identifier + 1;
		sector_name <- "Energetic Sector";
		riskType <- 'H';
		total_sector_value <- 0.0;
		do set_share_price(share_initial_price); 
		do set_share_risk(energetic_sector_share_risk);		
	}
	
	reflex 
	{
  		energetic_sector_share_price <- current_share_price;
		energetic_sector_value <- total_sector_value;
		energetic_sector_shares_count <- shares_issued;
	}
	
	aspect base {
	  draw file("../images/energetic.png") size: 15; 
	}
}

species tech_sector parent:sector{
	init{
		tech_sector_share_price <- share_initial_price;
		identifier <- identifier + 1;
		sector_name <- "Technologic Sector";
		riskType <- 'M';
		total_sector_value <- 0.0;
		do set_share_price(share_initial_price);
		do set_share_risk(tech_sector_share_risk);
	}
	
	reflex 
	{
	  	tech_sector_share_price <- current_share_price;
		tech_sector_value <- total_sector_value;
		tech_sector_shares_count <- shares_issued;
	}

	aspect base {
	  draw file("../images/tech.png") size: 15; 	
	}
}

species food_sector parent:sector{
	init{
		food_sector_share_price <- share_initial_price;
		identifier <- identifier + 1;
		sector_name <- "Food Sector";
		riskType <- 'L';
		total_sector_value <- 0.0;
		do set_share_price(share_initial_price);
		do set_share_risk(food_sector_share_risk);
	}
	
	reflex 
	{
	    food_sector_share_price <- current_share_price;
		food_sector_value <- total_sector_value;
		food_sector_shares_count <- shares_issued;
	}

	aspect base {
	  draw file("../images/food.png") size: 15; 			
	}
}

// Especie que representa un lote de acciones, con propiedades como el precio de compra, el precio esperado, y el riesgo asociado.
species share_batch{
	float purchase_price;
	float expectation_price;
	float last_price;
	float risk;
	int count_of <- 0;

	sector share_sector;
	
	// Reflejo condicionado por tiempo para recalcular el precio esperado de una acción.		
	reflex when : step mod time_to_recalculate_expectation_price = 0
	{		
		//El precio esperado puede ser más alto o más bajo que el precio actual de la acción, 
		//dependiendo del cambio de tendencia (si el precio está cayendo o subiendo). 
		//Cuanto más rápido cambie el precio, más fuertemente cambiarán las expectativas.
		int trend  <- last_price > share_sector.current_share_price ? -1 : 1;
		float b <- trend * abs(ln(share_sector.current_share_price / last_price));
		
		if(isDebug){write "-----------CALCULA expectation_price-----------------------";} //LOGS
		if(isDebug){write "SECTOR: " + share_sector.sector_name;} //LOGS
		if(isDebug){write "OLD expectation_price: " + expectation_price;} //LOGS	
		
		//Esta fórmula se basa en el cálculo de crecimiento exponencial, 
		//donde 'b' ajustará el crecimiento dependiendo de si el precio está subiendo o bajando y cuán volátil es la acción. 
		//Si 'b' es positivo, el precio esperado aumentará, reflejando un pronóstico de crecimiento en el valor de la acción. 
		//Si 'b' es negativo, el precio esperado disminuirá, anticipando una caída en el valor.
		expectation_price <- share_sector.current_share_price * exp(b);
		if(isDebug){write "NEW expectation_price: " + expectation_price;} //LOGS
		
		float crisis_risk <- rnd(0.0,1.0) with_precision 2;	
		if(isDebug){write "crisis_risk: " + crisis_risk + " | risk: " + risk;} //LOGS
		
		//Aquí intentamos provocar una crisis. 
		//Cuanto más riesgosas sean las acciones, mayor es la probabilidad de que ocurra una desviación en el precio esperado, 
		//lo que provocará el deseo de vender las acciones.
		if (crisis_risk <= risk)
		{
			if(isDebug){write "CRISIS: OLD expectation_price" + expectation_price;} //LOGS
			expectation_price <- expectation_price * (1 - risk);
			if(isDebug){write "CRISIS: NEW expectation_price: " + expectation_price;} //LOGS
			
			if(expectation_price < (share_sector.current_share_price * (1 - panic_price_decline)))
			{
				if(isDebug){write "PANICA current_share_price: " + share_sector.current_share_price;} //LOGS
				if(isDebug){write "PANICA Count shares to sell: " + count_of;} //LOGS
			}			
		}			
		
		last_price <- share_sector.current_share_price;
	}
}

species investor skills:[moving] control: simple_bdi{	
	int id_investor;
	
	float total_value;
	float initial_money;	
	float money;
	
	list<share_batch> my_shares <- [];
	
	float portion_high_risk;
	float portion_medium_risk;
	float portion_low_risk;
	
	point house_location;
	point high_risk_location;      /* ENERGETIC */
	point medium_risk_location;    /* TECH */
	point low_risk_location;       /* FOOD */	
	
	float speed;
	
	init{		
		id_investor <- identifier;
		identifier <- identifier + 1;
		speed <- rnd(0.02,0.06) with_precision 2;
		
		money <- rnd(15000.0,30000.0) with_precision 0; //por investor
		total_value <- money;
		initial_money <- money;
		
		ask energetic_sector{
			myself.high_risk_location <- self.location;
		}
		ask tech_sector{
			myself.medium_risk_location <- self.location;
		}
		ask food_sector{
			myself.low_risk_location <- self.location;
		}
	}
	
	action save_strategy_to_file(string type){
		float profit <- (total_value / initial_money) with_precision 2;
		save [step, type, id_investor, portion_high_risk, portion_medium_risk, portion_low_risk, initial_money, total_value, profit] rewrite: false to: "experiment_strategies_" + current_time + ".csv" format: csv;
	}
	
	//Acreditamos ingresos al usuario o declaramos la bancarrota si no quedan fondos y lo eliminamos del juego.
	reflex get_salary when: step mod 30.0 = 0 {		
			do get_income();		
			if(total_value < initial_money * share_of_remaining_capital)
			{
				hr_investor_count <- hr_investor_count - 1;
				investor_total_count <- investor_total_count - 1;
				bad_strategies <- bad_strategies + list([map('type'::'bad', 'id':: self.id_investor, 'hr':: self.portion_high_risk, 'mr':: self.portion_medium_risk, 'lr':: self.portion_low_risk, 'init_money':: self.initial_money with_precision 2, 'money':: self.total_value with_precision 2, 'profit':: (self.total_value / self.initial_money) with_precision 2 )]);
				do save_strategy_to_file('bad'); 				
				do die;
			}
	}
	
	//El método de acreditación de beneficios al inversor depende del volumen de acciones que posee y de su tasa de rentabilidad. 
	//Este proceso implica calcular la ganancia o el rendimiento que el inversor recibe de sus inversiones en acciones, 
	//basándose en dos factores principales:
	//1. Volumen de Acciones: Se refiere a la cantidad de acciones que el inversor tiene en su posesión. 
	//Este volumen puede variar según las compras y ventas que realice el inversor.
	//2. Tasa de Rentabilidad: Es el porcentaje de beneficio que se espera obtener de cada acción. 
	//Esta tasa puede variar según el tipo de acción, el desempeño de la empresa y las condiciones del mercado.
	action get_income {
			int index <- 0;			
			float income  <- my_shares sum_of (each.count_of * each.share_sector.current_share_price * (each.risk / 2));
			money <- money + income;		
			total_value <- money + my_shares sum_of (each.count_of * each.share_sector.current_share_price);
	}
	
	perceive target:house in:0 {		
		ask myself{
			do remove_belief(house_desire);
			do remove_intention(house_desire, true);
			do add_desire(get_next_sector());
		}
	}
	
	//Cuando el inversor se encuentra en un sector, intenta vender y comprar acciones de ese sector.
	perceive target:energetic_sector in:0 {
		focus id: sectorLocation var:location strength:10.0; 
		ask myself{
			do remove_belief(high_risk_shares_desire);
			do remove_intention(high_risk_shares_desire, true);
			
			float expenses <- get_expenses('H');
			
			float income <- 0.0;
			list<share_batch> share_to_sell <- my_shares 
				where (each.expectation_price < (each.share_sector.current_share_price * (1 - panic_price_decline)));

			ask energetic_sector {				
				//En este lugar, el inversor compra acciones.
				myself.my_shares <- myself.my_shares + sell_shares_to_me(expenses) - share_to_sell;				
				
				//En este lugar, el inversor vende acciones.				
				share_to_sell <- share_to_sell where (each.share_sector.sector_name = sector_name);
				if(length(share_to_sell) > 0){
					income <-  buy_my_shares(share_to_sell);			
				}
			}	
			do reduce_money(expenses);
			do increase_money(income);	
		}
	}
	
	perceive target:tech_sector in:0 {
		focus id: sectorLocation var:location strength:10.0; 
		ask myself{
			do remove_belief(medium_risk_shares_desire);
			do remove_intention(medium_risk_shares_desire, true);
			
			float expenses <- get_expenses('M');
			
			float income <- 0.0;
			list<share_batch> share_to_sell <- my_shares where (each.expectation_price < (each.share_sector.current_share_price *(1 - panic_price_decline)));

			ask tech_sector {				
				myself.my_shares <- myself.my_shares + sell_shares_to_me(expenses) - share_to_sell;	
				share_to_sell <- share_to_sell where (each.share_sector.sector_name = sector_name);				
				if(length(share_to_sell) > 0){
					income <-  buy_my_shares(share_to_sell);			
				}			
			}	
			do reduce_money(expenses);
			do increase_money(income);	
		}
	}
	
	perceive target:food_sector in:0 {
		focus id: sectorLocation var:location strength:10.0; 
		ask myself{
			do remove_belief(low_risk_shares_desire);
			do remove_intention(low_risk_shares_desire, true);
			
			float expenses <- get_expenses('L');
			
			float income <- 0.0;
			list<share_batch> share_to_sell <- my_shares where (each.expectation_price < (each.share_sector.current_share_price * (1 - panic_price_decline)));

			ask food_sector {				
				myself.my_shares <- myself.my_shares + sell_shares_to_me(expenses) - share_to_sell;	
				share_to_sell <- share_to_sell where (each.share_sector.sector_name = sector_name);				
				if(length(share_to_sell) > 0){
					income <-  buy_my_shares(share_to_sell);			
				}		
			}	
			do reduce_money(expenses);
			do increase_money(income);	
		}
	}
	
	rule belief: new_predicate(sectorLocation) new_desire: house_desire;
	rule belief: new_predicate(houseLocation) new_desire: sector_desire;
	
	plan goto_high_risk intention: high_risk_shares_desire {		
		do goto target: high_risk_location speed: self.speed;//rnd(0.03,0.05);
	}
	
	plan goto_medium_risk intention: medium_risk_shares_desire {		
		do goto target: medium_risk_location speed: self.speed;//rnd(0.015,0.025);
	}
	
	plan goto_low_risk intention: low_risk_shares_desire {		
		do goto target: low_risk_location speed: self.speed;//rnd(0.005,0.01);
	}
	
	plan goto_house intention: house_desire {
		do goto target: house_location speed: self.speed;
	}
	
	action increase_money(float amount){
		money <- money + amount;
	}
	
	action reduce_money(float amount){
			money <- money - amount;			
			if (money < 0)
			{
				money <- 0.0;
			}				
	}

		//Aquí, el inversor determina a qué sector irá. 
		//El sector estará disponible si todavía es posible comprar acciones en él o si hay un deseo de vender acciones de ese sector.
		predicate get_next_sector{
			list<predicate> available_predicates <- [];
			
			if (check_sharesRiskTypeValue('H'))
			{
				available_predicates <- available_predicates + high_risk_shares_desire;
			}
			
			if (check_sharesRiskTypeValue('M'))
			{
				available_predicates <- available_predicates + medium_risk_shares_desire;
			}
			
			if (check_sharesRiskTypeValue('L'))
			{
				available_predicates <- available_predicates + low_risk_shares_desire;
			}
			
			return one_of(available_predicates);
		}
	
		//Aquí comprobamos la disponibilidad del sector. Un sector está disponible si:
		//1. Hay acciones disponibles para vender en este sector.
		//2. Hay una oportunidad de comprar acciones en este sector. 
		//Se pueden comprar acciones si el inversor aún no ha gastado todo su dinero disponible para este sector, 
		//de acuerdo con su estrategia de inversión.
		bool check_sharesRiskTypeValue(string risk_type){
			list<share_batch> sharesRiskTypeList <- my_shares where (each.share_sector.riskType = risk_type);
			
			int shares_count <-  sharesRiskTypeList sum_of (each.count_of);	
			
			float sharesRiskTypeValue <- 0.0;
			if (shares_count > 0)
			{
				sharesRiskTypeValue <- shares_count * (sharesRiskTypeList at 0).share_sector.current_share_price;
			}
			
			if(length(sharesRiskTypeList where (each.expectation_price < (each.share_sector.current_share_price * (1 - panic_price_decline)))) > 0)
			{
				return true;
			}
			
			if(risk_type = 'H')
			{
				return sharesRiskTypeValue / total_value < portion_high_risk;
			}
			else if(risk_type = 'M')
			{
				return sharesRiskTypeValue / total_value < portion_medium_risk;
			}
			else 
			{
				return sharesRiskTypeValue / total_value < portion_low_risk;
			}					
		}
	
		//Método para obtener fondos disponibles para invertir. 
		//En una sola operación de compra, el inversor no puede gastar más del 20% de los fondos disponibles en su cuenta.
		float get_expenses(string risk_type){
			list<share_batch> sharesRiskTypeList <- my_shares where (each.share_sector.riskType = risk_type);
			
			int shares_count <-  sharesRiskTypeList sum_of (each.count_of);
			
			float sharesRiskTypeValue <- 0.0;
			if (shares_count > 0)
			{
				sharesRiskTypeValue <- shares_count * (sharesRiskTypeList at 0).share_sector.current_share_price;
			}
			
			//portion_high_risk
			if(risk_type = 'H')
			{
				float part <- portion_high_risk - sharesRiskTypeValue / total_value;
				return part <= part_to_spend ? part * money : part_to_spend * money; 
			}
			//portion_medium_risk
			else if(risk_type = 'M')
			{
				float part <- portion_medium_risk - sharesRiskTypeValue / total_value;
				return part <= part_to_spend ? part * money : part_to_spend * money;  
			}
			//portion_low_risk
			else 
			{
				float part <- portion_low_risk - sharesRiskTypeValue / total_value;
				return part <= part_to_spend ? part * money : part_to_spend * money; 
			}					
		}
}

species aggressive_investor parent:investor{
	init{
		portion_medium_risk <- rnd(0.0, 0.5) with_precision 2;
		portion_low_risk <- rnd(0.0, 0.5) with_precision 2;
		portion_high_risk <- (1.0 - portion_medium_risk - portion_low_risk) with_precision 2;		
		do add_desire(high_risk_shares_desire);
	}

	aspect base{
		draw file("../images/eagle.png") size: 3; 
	}
}

species moderate_investor parent:investor{
	init{
		portion_high_risk <- rnd(0.0, 0.15) with_precision 2;
		portion_low_risk <- rnd(0.0, 0.15) with_precision 2;
		portion_medium_risk <- (1.0 - portion_high_risk - portion_low_risk) with_precision 2;
		do add_desire(medium_risk_shares_desire);
	}	
	
	aspect base{
		draw file("../images/dolphin.png") size: 3; 
	}
}

species conservative_investor parent:investor{
	init{
		portion_high_risk <- rnd(0.0, 0.15) with_precision 2;
		portion_medium_risk <- rnd(0.0, 0.15) with_precision 2;
		portion_low_risk <- (1.0 - portion_high_risk - portion_medium_risk) with_precision 2;
		do add_desire(low_risk_shares_desire);
	}
	
	aspect base{
		draw file("../images/turtle.png") size: 3; 
	}	
}



experiment Abp_experimento_1 type: gui {
	float minimum_cycle_duration <- 0.1;
	/** Insert here the definition of the input and output of the model */
	output {					
		display view1 { 
			grid gworld border: #white;
			species food_sector aspect:base;
			species energetic_sector aspect:base;
			species tech_sector aspect:base;
			species house aspect:base;
			species moderate_investor aspect:base;
			species conservative_investor aspect:base;
			species aggressive_investor aspect:base;
		}
		display "match_stats"  type: 2d {
			// display some statistics about the game
			chart "Value of sectores" type:pie position:{0,0} size:{0.5,0.5} {
				data "Energetic (red) possession" value: energetic_sector_value color:#red;
				data "Tech (blue) " value: tech_sector_value color:#blue;
				data "Food (green) sector" value: food_sector_value color:#green;
			}
			chart "number investors" type:series position:{0.5,0} size:{0.5,0.5} {
				data "Agressive" value:hr_investor_count color:#red;
				data "Moderate" value:mr_investor_count color:#blue;
				data "Conservative" value:lr_investor_count color:#green;
			}
			chart "share price" type:series position:{0.5,0.5} size:{0.5,0.5} {
				data "Energetic" value:energetic_sector_share_price color:#red;
				data "Tech" value:tech_sector_share_price color:#blue;
				data "Food" value:food_sector_share_price color:#green;
			}
			chart "Number shares of sectores" type:pie position:{0,0.5} size:{0.5,0.5} {
				data "Energetic (red) possession" value: energetic_sector_shares_count color:#red;
				data "Tech (blue) " value: tech_sector_shares_count color:#blue;
				data "Food (green) sector" value: food_sector_shares_count color:#green;
			}
		}
	}
}