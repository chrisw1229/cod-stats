(ns org.stoop.codData)

;Weapon categories

(def *pistols* ["luger_mp" 
		"colt_mp" 
		"webley_mp" 
		"tt33_mp"])

(def *rifles* ["gewehr43_mp" 
	       "svt40_mp" 
	       "m1garand_mp" 
	       "enfield_mp" 
	       "m1carbine_mp" 
	       "kar98k_mp" 
	       "mosin_nagant_mp"])

(def *light-mgs* ["mp44_mp" 
		  "mp44_semi_mp" 
		  "thompson_mp" 
		  "thompson_semi_mp" 
		  "mp40_mp" "ppsh_mp" 
		  "ppsh_semi_mp" 
		  "bren_mp" 
		  "sten_mp" 
		  "silenced_sten_mp"])

(def *heavy-mgs* ["30cal_tank_mp" 
		  "50cal_tank_mp" 
		  "dp28_mp" 
		  "mg30cal_mp"
		  "mg34_mp" 
		  "mg34_tank_mp" 
		  "mg42_bipod_duck_mp" 
		  "mg42_bipod_prone_mp"
		  "mg42_bipod_stand_mp" 
		  "mg42_turret_mp" 
		  "mg50cal_tripod_stand_mp"
		  "mg_sg43_tank_mp" 
		  "sg43_turret_mp"])

(def *grenades* ["fraggrenade_mp" 
		 "mk1britishfrag_mp" 
		 "rgd-33russianfrag_mp"
		 "stielhandgranate_mp" 
		 "satchelcharge_mp" 
		 "smokegrenade_mp"])

(def *tanks* ["elefant_turret_mp" 
	      "panzeriv_turret_mp" 
	      "sherman_turret_mp"
	      "su152_turret_mp" 
	      "t34_turret_mp"])

(def *jeeps* ["cal_tank_mp" "50cal_tank_mp"])

(def *artillery* ["binoculars_artillery_mp" "flak88_turret_mp"])

(def *bazookas* ["bazooka_mp" 
		 "panzerfaust_mp" 
		 "panzerschreck_mp"])

(def *fubars* ["bazooka_fubar_mp" 
	       "panzerfaust_fubar_mp" 
	       "panzerschreck_fubar_mp"])

;Country's weapons

(def *american-weapons* ["m1carbine_mp" 
			 "m1garand_mp" 
			 "thompson_mp" 
			 "thompson_semi_mp"
			 "bar_mp" 
			 "bar_slow_mp" 
			 "springfield_mp" 
			 "mg30cal_mp"
			 "fraggrenade_mp"])

(def *russian-weapons* ["mosin_nagant_mp" 
			"ppsh_mp" 
			"svt40_mp" 
			"mosin_nagant_sniper_mp"
			"dp28_mp" 
			"rgd-33russiangrag_mp"])

(def *british-weapons* ["enfield_mp" 
			"sten_mp" 
			"bren_mp" 
			"springfield_mp" 
			"mg30cal_mp"
			"mk1britishfrag_mp"])

(def *german-weapons* ["kar98k_mp" 
		       "mp40_mp" 
		       "mp44_mp" 
		       "mp44_semi_mp" 
		       "gewehr43_mp"
		       "kar98k_sniper_mp" 
		       "mg34_mp" 
		       "stielhandgranate_mp"])