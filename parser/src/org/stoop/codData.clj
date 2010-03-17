(ns org.stoop.codData
  (:use clojure.contrib.seq-utils))

;Map data
(defn make-coord-transformer [constant x-multiplier y-multiplier]
  #(+ (+ constant (* x-multiplier %1)) (* y-multiplier %2)))

(def map-transformers {"mp_uo_carentan" {:x (make-coord-transformer 3036.99 -0.0005 -0.748)
					 :y (make-coord-transformer 2405.06 -0.746 0.0149)}
		       "mp_uo_harbor" {:x (make-coord-transformer -3756.58 -0.6532 0.01429)
				       :y (make-coord-transformer 6871.9 0.00896 0.6459)}
		       "mp_kursk" {:x (make-coord-transformer 471.294 -0.00459 -0.1852)
				   :y (make-coord-transformer 1963.22 -0.1859 0.002067)}
		       "mp_uo_dawnville" {:x (make-coord-transformer 8698.9 0.4451 0.39842)
					  :y (make-coord-transformer -5625.61 0.3846 -0.44599)}
		       "mp_uo_hurtgen" {:x (make-coord-transformer 1670.37 0.35984 0.005116)
					:y (make-coord-transformer 1699.43 0.002471 -0.36013)}
		       "mp_peaks" {:x (make-coord-transformer 2619.06 0.5361 -0.01583)
				   :y (make-coord-transformer 2222.38 -0.002845 -0.5383)}
		       "mp_foy" {:x (make-coord-transformer 2062.27 0.001055 0.2315)
				 :y (make-coord-transformer 2158.63 0.2345 0.000368)}
		       "mp_uo_stanjel" {:x (make-coord-transformer 1706.93 -0.5531 -0.01042)
					:y (make-coord-transformer 752.86 -0.01206 0.56215)}
		       "mp_arnhem" {:x (make-coord-transformer 2191.49 0.6545 -0.003142)
				    :y (make-coord-transformer 2703.83 0.00107 -0.6466)}
		       "mp_uo_powcamp" {:x (make-coord-transformer 1249.65 -0.0051 0.5042)
					:y (make-coord-transformer 2181.31 0.5002 0.00173)}
		       "mp_berlin" {:x (make-coord-transformer 3345.23 0.4493 0.000073669)
				    :y (make-coord-transformer 3343.8 -0.002766 -0.4605)}
		       "mp_bocage" {:x (make-coord-transformer 1271.94 0.02848 0.2354)
				    :y (make-coord-transformer 2352.14 0.2367 -0.023267)}
		       "mp_brecourt" {:x (make-coord-transformer 1801.21 0.447 -0.003862)
				      :y (make-coord-transformer 1431.46 0.157 -0.4881)}
		       "mp_cassino" {:x (make-coord-transformer 746.29 0.4168 -0.001304)
				     :y (make-coord-transformer 1656.26 -0.0009419 -0.4177)}
		       "mp_chateau" {:x (make-coord-transformer 1640.29 1.0396 -0.008571)
				     :y (make-coord-transformer 3033.23 -0.005201 -1.0373)}
		       "mp_neuville" {:x (make-coord-transformer 10673.55 0.6144 0.01809)
				      :y (make-coord-transformer 4396.89 -0.001637 -0.6379)}
		       "mp_italy" {:x (make-coord-transformer 2202.59 0.002778 0.2025)
				   :y (make-coord-transformer 1973.99 0.2021 0.001427)}
		       "mp_uo_depot" {:x (make-coord-transformer 2006.08 -0.00362 0.57603)
				      :y (make-coord-transformer 2752.87 0.5688 0.004178)}
		       "mp_streets" {:x (make-coord-transformer -671.16 0.003213 -0.4655)
				     :y (make-coord-transformer 2809.23 -0.4742 0.001135)}
		       "enclave" {:x (make-coord-transformer 1909.75 -0.3634 -0.002011)
				  :y (make-coord-transformer 2505.98 -0.001483 0.3604)}
		       "jeeparena" {:x (make-coord-transformer 2146.47 -0.002134 -0.2482)
				    :y (make-coord-transformer 1969.07 -0.2472 0.002444)}
		       "mp_pavlov" {:x (make-coord-transformer 7308.46 -0.001906 -0.5576)
				    :y (make-coord-transformer -2982.32 -0.5549 -0.002028)}
		       "mp_ponyri" {:x (make-coord-transformer 1399.05 -0.00007585 -0.1922)
				    :y (make-coord-transformer 2559.21 -0.1919 0.003295)}
		       "mp_railyard" {:x (make-coord-transformer 1564.88 0.01408 0.523)
				      :y (make-coord-transformer 2697.46 0.5087 0.001226)}
		       "reserves" {:x (make-coord-transformer 1983.35 -0.002727 0.5899)
				   :y (make-coord-transformer 1660.26 0.5875 0.002758)}
		       "mp_rhinevalley" {:x (make-coord-transformer 3236.26 -0.1621 0.109)
					 :y (make-coord-transformer 3035.92 0.1096 0.1499)}
		       "mp_rocket" {:x (make-coord-transformer -2277.55 0.285 0.3392)
				    :y (make-coord-transformer -25.95 0.3367 -0.2829)}
		       "mp_ship" {:x (make-coord-transformer 3953.61 0.3997 -0.01218)
				  :y (make-coord-transformer 2141.3 0.0007916 -0.4194)}
		       "mp_sicily" {:x (make-coord-transformer 618.45 -0.3659 0.09869)
				    :y (make-coord-transformer 1798.28 0.09372 0.3698)}
		       "mp_stalingrad" {:x (make-coord-transformer -493.67 0.716 -0.003368)
					:y (make-coord-transformer 1313.59 0.00728 -0.706)}
		       "warehousefun" {:x (make-coord-transformer -196.52 -0.005807 1.688)
				       :y (make-coord-transformer 5140.77 1.688 0.002167)}})

(defn get-transformer [map-name]
  (get map-transformers map-name {:x (make-coord-transformer 0 1 1)
				  :y (make-coord-transformer 0 1 1)}))

;Weapon categories

(def pistols ["luger_mp" 
	      "colt_mp" 
	      "webley_mp" 
	      "tt33_mp"])
(defn pistol? [weapon-name]
  (includes? pistols  weapon-name))

(def rifles ["gewehr43_mp" 
	     "svt40_mp" 
	     "m1garand_mp" 
	     "enfield_mp" 
	     "m1carbine_mp" 
	     "kar98k_mp" 
	     "mosin_nagant_mp"])
(defn rifle? [weapon-name]
  (includes? rifles weapon-name))

(def light-mgs ["mp44_mp" 
		"mp44_semi_mp" 
		"thompson_mp" 
		"thompson_semi_mp" 
		"mp40_mp" "ppsh_mp" 
		"ppsh_semi_mp" 
		"bren_mp" 
		"sten_mp" 
		"silenced_sten_mp"])
(defn light-mg? [weapon-name]
  (includes? light-mgs  weapon-name))

(def heavy-mgs ["30cal_tank_mp" 
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
(defn heavy-mg? [weapon-name]
  (includes? heavy-mgs weapon-name))

(def grenades ["fraggrenade_mp" 
	       "mk1britishfrag_mp" 
	       "rgd-33russianfrag_mp"
	       "stielhandgranate_mp" 
	       "satchelcharge_mp" 
	       "smokegrenade_mp"])
(defn grenade? [weapon-name]
  (includes? grenades weapon-name))

(def tanks ["elefant_turret_mp" 
	    "panzeriv_turret_mp" 
	    "sherman_turret_mp"
	    "su152_turret_mp" 
	    "t34_turret_mp"])
(defn tank? [weapon-name]
  (includes? tanks weapon-name))

(def jeeps ["cal_tank_mp" "50cal_tank_mp"])
(defn jeep? [weapon-name]
  (includes? jeeps weapon-name))

(def artillery ["binoculars_artillery_mp" "flak88_turret_mp"])
(defn artillery? [weapon-name]
  (includes? artillery weapon-name))

(def bazookas ["bazooka_mp" 
	       "panzerfaust_mp" 
	       "panzerschreck_mp"])
(defn bazooka? [weapon-name]
  (includes? bazookas weapon-name))

(def fubars ["bazooka_fubar_mp" 
	     "panzerfaust_fubar_mp" 
	     "panzerschreck_fubar_mp"])
(defn fubar? [weapon-name]
  (includes? fubars weapon-name))

;Country's weapons

(def american-weapons ["m1carbine_mp" 
		       "m1garand_mp" 
		       "thompson_mp" 
		       "thompson_semi_mp"
		       "bar_mp" 
		       "bar_slow_mp" 
		       "springfield_mp" 
		       "mg30cal_mp"
		       "fraggrenade_mp"])
(defn american? [weapon-name]
  (includes? american-weapons weapon-name))

(def russian-weapons ["mosin_nagant_mp" 
		      "ppsh_mp" 
		      "svt40_mp" 
		      "mosin_nagant_sniper_mp"
		      "dp28_mp" 
		      "rgd-33russiangrag_mp"])
(defn russian? [weapon-name]
  (includes? russian-weapons weapon-name))

(def british-weapons ["enfield_mp" 
		      "sten_mp" 
		      "bren_mp" 
		      "springfield_mp" 
		      "mg30cal_mp"
		      "mk1britishfrag_mp"])
(defn british? [weapon-name]
  (includes? british-weapons weapon-name))

(def german-weapons ["kar98k_mp" 
		     "mp40_mp" 
		     "mp44_mp" 
		     "mp44_semi_mp" 
		     "gewehr43_mp"
		     "kar98k_sniper_mp" 
		     "mg34_mp" 
		     "stielhandgranate_mp"])
(defn german? [weapon-name]
  (includes? german-weapons weapon-name))

(defn jeep-crush? [type-name]
  (includes? ["MOD_JEEP_CRUSH"] type-name))
(defn tank-crush? [type-name]
  (includes? ["MOD_TANK_CRUSH"] type-name))
(defn flame-thrower? [weapon-name]
  (includes? ["flamethrower_mp"] weapon-name))
(defn melee? [type-name]
  (includes? ["MOD_MELEE"] type-name))






