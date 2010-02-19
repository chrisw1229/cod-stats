(ns org.stoop.codData
  (:use clojure.contrib.seq-utils))

;Map data
(defn make-coord-transformer [constant x-multiplier y-multiplier]
  #(+ (+ constant (* x-multiplier %1)) (* y-multiplier %2)))

(def *map-transformers* {"mp_uo_carentan" {:x (make-coord-transformer 3036.99 -0.0005 -0.748)
					   :y (make-coord-transformer 2405.06 -0.746 0.0149)}
			 "mp_carentan" {:x (make-coord-transformer 3036.99 -0.0005 -0.748)
					:y (make-coord-transformer 2405.06 -0.746 0.0149)}
			 "mp_uo_harbor" {:x (make-coord-transformer -3884.41 -0.654 -0.00161)
					 :y (make-coord-transformer 1238.79 -0.0321 -0.0459)}
			 "mp_kursk" {:x (make-coord-transformer 4712.94 -0.00459 -0.1852)
				     :y (make-coord-transformer 1963.22 -0.1859 -0.002067)}})

(defn get-transformer [map-name]
  (get *map-transformers* map-name {:x (make-coord-transformer 0 1 1)
				    :y (make-coord-transformer 0 1 1)}))

;Weapon categories

(def *pistols* ["luger_mp" 
		"colt_mp" 
		"webley_mp" 
		"tt33_mp"])
(defn is-pistol? [weapon-name]
  (includes? *pistols*  weapon-name))

(def *rifles* ["gewehr43_mp" 
	       "svt40_mp" 
	       "m1garand_mp" 
	       "enfield_mp" 
	       "m1carbine_mp" 
	       "kar98k_mp" 
	       "mosin_nagant_mp"])
(defn is-rifle? [weapon-name]
  (includes? *rifles*  weapon-name))

(def *light-mgs* ["mp44_mp" 
		  "mp44_semi_mp" 
		  "thompson_mp" 
		  "thompson_semi_mp" 
		  "mp40_mp" "ppsh_mp" 
		  "ppsh_semi_mp" 
		  "bren_mp" 
		  "sten_mp" 
		  "silenced_sten_mp"])
(defn is-light-mg? [weapon-name]
  (includes? *light-mgs*  weapon-name))

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
(defn is-heavy-mg? [weapon-name]
  (includes? *heavy-mgs* weapon-name))

(def *grenades* ["fraggrenade_mp" 
		 "mk1britishfrag_mp" 
		 "rgd-33russianfrag_mp"
		 "stielhandgranate_mp" 
		 "satchelcharge_mp" 
		 "smokegrenade_mp"])
(defn is-grenade? [weapon-name]
  (includes? *grenades* weapon-name))

(def *tanks* ["elefant_turret_mp" 
	      "panzeriv_turret_mp" 
	      "sherman_turret_mp"
	      "su152_turret_mp" 
	      "t34_turret_mp"])
(defn is-tank? [weapon-name]
  (includes? *tanks* weapon-name))

(def *jeeps* ["cal_tank_mp" "50cal_tank_mp"])
(defn is-jeep? [weapon-name]
  (includes? *jeeps* weapon-name))

(def *artillery* ["binoculars_artillery_mp" "flak88_turret_mp"])
(defn is-artillery? [weapon-name]
  (includes? *artillery* weapon-name))

(def *bazookas* ["bazooka_mp" 
		 "panzerfaust_mp" 
		 "panzerschreck_mp"])
(defn is-bazooka? [weapon-name]
  (includes? *bazookas* weapon-name))

(def *fubars* ["bazooka_fubar_mp" 
	       "panzerfaust_fubar_mp" 
	       "panzerschreck_fubar_mp"])
(defn is-fubar? [weapon-name]
  (includes? *fubars* weapon-name))

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
(defn is-american? [weapon-name]
  (includes? *american-weapons* weapon-name))

(def *russian-weapons* ["mosin_nagant_mp" 
			"ppsh_mp" 
			"svt40_mp" 
			"mosin_nagant_sniper_mp"
			"dp28_mp" 
			"rgd-33russiangrag_mp"])
(defn is-russian? [weapon-name]
  (includes? *russian-weapons* weapon-name))

(def *british-weapons* ["enfield_mp" 
			"sten_mp" 
			"bren_mp" 
			"springfield_mp" 
			"mg30cal_mp"
			"mk1britishfrag_mp"])
(defn is-british? [weapon-name]
  (includes? *british-weapons*  weapon-name))

(def *german-weapons* ["kar98k_mp" 
		       "mp40_mp" 
		       "mp44_mp" 
		       "mp44_semi_mp" 
		       "gewehr43_mp"
		       "kar98k_sniper_mp" 
		       "mg34_mp" 
		       "stielhandgranate_mp"])
(defn is-german? [weapon-name]
  (includes? *german-weapons*  weapon-name))

(defn is-jeep-crush? [weapon-name]
  (includes? ["jeepcrush_mp"] weapon-name))
(defn is-tank-crush? [weapon-name]
  (includes? ["tankcrush_mp"] weapon-name))
(defn is-flame-thrower? [weapon-name]
  (includes? ["flamethrower_mp"] weapon-name))
(defn is-melee? [type-name]
  (includes? ["MOD_MELEE"] type-name))






