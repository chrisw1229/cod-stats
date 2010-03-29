;web stuff
(ns org.stoop.codStatsServlet
  (:gen-class :extends javax.servlet.http.HttpServlet)
  (:use org.stoop.codStatsIo org.stoop.codStatsRealTime org.stoop.codIdentity org.stoop.codAnalytics
	org.stoop.schedule
	org.danlarkin.json
	compojure.http clojure.contrib.seq-utils))

(def max-map-records 20)

(defn parse-integer [str]
  (try (Integer/parseInt str) 
       (catch NumberFormatException nfe 0)))

(defn map-record? [record]
  (or
   (and (contains? record :kx)
	(contains? record :ky)
	(contains? record :dx)
	(contains? record :dy))
   (and (contains? record :sx)
	(contains? record :sy))))

(defn game-record? [record]
  (and (contains? record :map)
       (contains? record :type)
       (contains? record :time)))

(defn event-record? [record] 
  (and (contains? record :team)
       (contains? record :time)))

(defn heartbeat-event? [record]
  (and (contains? record :time)
	(= 1 (count record))))

(defn player-record? [record]
  (and (contains? record :name)
       (contains? record :team)))

(defn unique-player-records
  [records]
  (let [ids (set (for [player records] (:id player)))]
    (for [id ids]
      (last (filter #(= id (:id %)) records)))))

(defn process-records [records]
  (let [map-records (filter map-record? records)
	game-records (filter game-record? records)
	event-records (filter event-record? records)
	heartbeats (filter heartbeat-event? records)
	player-records (unique-player-records (filter player-record? records))]
    (flatten (filter #(not (nil? %)) [(when (> (count game-records) 0)
					{:type "game" :data (last game-records)})
				      
				      (when (> (count map-records) 0)
					(for [record (take max-map-records (reverse map-records))]
					  {:type "map" :data record}))
				      
				      (when (> (count event-records) 0)
					(for [record event-records]
					  {:type "event" :data record}))

				      (when (> (count heartbeats) 0)
					{:type "event" :data (last heartbeats)})
				      
				      (when (> (count player-records) 0)
					(for [record player-records]
					  {:type "player" :data record}))]))))

(defn format-award
  [award-list]
  (encode-to-str
   {:columns [{:name "Name" :type "string"}
	      {:name "Value" :type "number" :sort false}]
    :rows (for [award award-list :when (not (nil? (:name award)))]
	    [(:name award) (:value award)])}))

(defn reverse-format-award
  [award-list]
  (encode-to-str
   {:columns [{:name "Name" :type "string"}
	      {:name "Value" :type "number" :sort true}]
    :rows (for [award award-list :when (not (nil? (:name award)))]
	    [(:name award) (:value award)])}))

(defroutes cod-stats-routes
  (GET "/stats/live"
       (let [ts (parse-integer (:ts params))]
	 (if (<= ts (count @game-records))
	   (encode-to-str (conj (process-records (drop ts @game-records)) 
				{:type "ts" :data (count @game-records)}))
	   (encode-to-str (conj (process-records @game-records) 
				{:type "ts" :data (count @game-records)})))))
	
  (GET "/stats/start"
       (when (not (nil? (:log params)))
	 (dosync (ref-set *log-file-location* (:log params))))
       (when (not (nil? (:conn params)))
	 (dosync (ref-set *connect-log-location* (:conn params))))
       (let [log-reader (tail-f @*log-file-location* 1000 process-input-line)
	     connect-reader (tail-f @*connect-log-location* 1000 process-connect-line)]
	 ;Start log readers
	 ((:start connect-reader))
	 ((:start log-reader))
	 ;Start trend calculation to repeat once every minute
	 (fixedrate {:name "Trend"
		     :task #(update-ratios player-stats-map player-id-ratio-map)
		     :start-delay 0
		     :rate 1
		     :unit (:minutes unit)})
	 ;Start event heartbeat for jeep meter once every 5 seconds
	 (fixedrate {:name "Heartbeat"
		     :task #(heartbeat-game-event (last @game-archive))
		     :start-delay 0
		     :rate 5
		     :unit (:seconds unit)})
	 (str "File watching started for " @*log-file-location*)))

  (GET "/stats/archive"
       (encode-to-str @ip-id-map))

  (GET "/stats/registration"
       (let [ip-address (:ip params)
	     photo (:photo params)]
	 (when (and (not (nil? photo)) (not (nil? ip-address)))
	   (set-photo ip-address photo)
	   (str "Photo set to " photo " for " ip-address))))

  (GET "/stats/players/:index.json"
       (encode-to-str
	(get-ip-photo-name)))

  (GET "/stats/leaderboard/:leader.json"
       (encode-to-str
	{:columns [{:name "Player Name" :type "string"}
		   {:name "Kills" :type "number"}
		   {:name "Deaths" :type "number"}
		   {:name "Suicides" :type "number"}
		   {:name "Time" :type "number"}
		   {:name "Damage Inflicted" :type "number"}
		   {:name "Damage Received" :type "number"}
		   {:name "Best Weapon" :type "number"}
		   {:name "Best Enemy" :type "string"}]
	 :rows (get-all-leaderboard-stats @game-archive)}))

  (GET "/stats/awards/:award.json"
       (let [award (:award params)]
	 (cond
	  (= award "index")
	  (encode-to-str 
	   [{:name "Bulldozer" :id "bulldozer" :tip "Most damage to world objects."}
	    {:name "Broken Ankles" :id "broken_ankles" :tip "Most damage due to falling."}
	    {:name "Burning Man" :id "burning_man" :tip "Most self inflicted fire damage."}
	    {:name "Chatty Cathy" :id "chatty_cathy" :tip "Highest number of chat messages sent."}
	    {:name "Darwin" :id "darwin" :tip "Most damage from the environment."}
	    {:name "Death Frenzy" :id "death_frenzy" :tip "Highest streak of deaths without a kill."}
	    {:name "Elusive" :id "elusive" :tip "Lowest kills plus deaths."}
	    {:name "Kill Frenzy" :id "kill_frenzy" :tip "Highest streak of kills without a death."}
	    {:name "Lamer" :id "lamer" :tip "Number of melee plus artillery kills."}
	    {:name "Lemming" :id "lemming" :tip "Most deaths by suicide."}
	    {:name "Masochist" :id "masochist" :tip "Most self-inflicted damage."}
	    {:name "Scapegoat" :id "scapegoat" :tip "Most damage received from teammates."}
	    {:name "Scavenger" :id "scavenger" :tip "Most weapon pickups."}
	    {:name "The Shocker" :id "shocker" :tip "Most time spent shell shocked."}
	    {:name "Traitor" :id "traitor" :tip "Most team kills."}
	    {:name "Watery Grave" :id "watery_grave" :tip "Most deaths by water."}
	    {:name "Wolverine" :id "wolverine" :tip "Most health pickups."}
	    {:name "Artillery" :id "artillery" :tip "Most damage done by artillery weapons."}
	    {:name "Bazooka" :id "bazooka" :tip "Most damage done by bazooka."}
	    {:name "Comrade" :id "comrade" :tip "Most kills by Russian weapons."}
	    {:name "Crotch Shot" :id "crotch_shot" :tip "Most kills by hits to the lower torso."}
	    {:name "Flamethrower" :id "flamethrower" :tip "Most damage done by flamethrower."}
	    {:name "FUBAR" :id "fubar" :tip "Most damage done by FUBAR weapons."}
	    {:name "Grenade" :id "grenade" :tip "Most damage done by grenades."}
	    {:name "Heavy Machine Gun" :id "heavy_mg" :tip "Most kills by heavy machine gun."}
	    {:name "Jeep" :id "jeep" :tip "Most kills by mounted jeep gun."}
	    {:name "Jeep Crush" :id "jeep_crush" :tip "Most damage by jeep crush."}
	    {:name "Light Machine Gun" :id "light_mg" :tip "Most kills by light machine gun."}
	    {:name "Limb Shot" :id "limb_shot" :tip "Most kills by hits to the arm, leg, hand or foot."}
	    {:name "Limey" :id "limey" :tip "Most kills by British weapons."}
	    {:name "Marksmanship" :id "marksmanship" :tip "Most kills by hits to the head or neck."}
	    {:name "Nazi" :id "nazi" :tip "Most kills by German weapons."}
	    {:name "Pistol" :id "pistol" :tip "Most kills by pistol."}
	    {:name "Rifle" :id "rifle" :tip "Most kills by rifle."}
	    {:name "Scorched Earth" :id "scorched_earth" :tip "Most damage dealt."}
	    {:name "Tank" :id "tank" :tip "Most kills by tank."}
	    {:name "Tank Crush" :id "tank_crush" :tip "Most damage by tank crush."}
	    {:name "Yankee" :id "yankee" :tip "Most kills by American weapons."}
	    {:name "CTF - Agent" :id "ctf_agent" :tip "Most flags stolen from an enemy base."}
	    {:name "CTF - Conqueror" :id "ctf_conqueror" :tip "Most enemy flags returned to home flag."}
	    {:name "CTF - Hero" :id "ctf_hero" :tip "Most dropped friendly flags picked up."}
	    {:name "CTF - Ranger" :id "ctf_ranger" :tip "Most dropped enemy flags picked up."}
	    {:name "CTF - Winner" :id "ctf_winner" :tip "Most times on winning team for CTF."}
	    {:name "CTF - Loser" :id "ctf_loser" :tip "Most times on losing team for CTF."}
	    {:name "DOM - Agent" :id "dom_agent" :tip "Most attempted flag point captures."}
	    {:name "DOM - Conqueror" :id "dom_conqueror" :tip "Most flag points captured."}
	    {:name "DOM - Defender" :id "dom_defender" :tip "Most kills near a friendly flag point."}
	    {:name "DOM - Patriot" :id "dom_patriot" :tip "Most deaths near a flag point."}
	    {:name "DOM - Wingman" :id "dom_wingman" :tip "Most kills near an enemy flag point."}
	    {:name "DOM - Winner" :id "dom_winner" :tip "Most times on winning team for DOM."}
	    {:name "DOM - Loser" :id "dom_loser" :tip "Most times on losing team for DOM."}
	    {:name "FTF - Agent" :id "ftf_agent" :tip "Most cows picked up."}
	    {:name "FTF - Conqeror" :id "ftf_conqueror" :tip "Most cows scored."}
	    {:name "FTF - Defender" :id "ftf_defender" :tip "Most kills near a friendly cow carrier."}
	    {:name "FTF - Patriot" :id "ftf_patriot" :tip "Most deaths near a cow."}
	    {:name "FTF - Wingman" :id "ftf_wingman" :tip "Most kills near a cow carrier."}
	    {:name "FTF - Winner" :id "ftf_winner" :tip "Most times on winning team for FTF."}
	    {:name "FTF - Loser" :id "ftf_loser" :tip "Most times on losing team for FTF."}
	    {:name "SFTF - Agent" :id "sftf_agent" :tip "Most cows picked up."}
	    {:name "SFTF - Conqeror" :id "sftf_conqueror" :tip "Most cows scored."}
	    {:name "SFTF - Defender" :id "sftf_defender" :tip "Most kills near a friendly cow carrier."}
	    {:name "SFTF - Patriot" :id "sftf_patriot" :tip "Most deaths near a cow."}
	    {:name "SFTF - Wingman" :id "sftf_wingman" :tip "Most kills near a cow carrier."}
	    {:name "SFTF - Winner" :id "sftf_winner" :tip "Most times on winning team for SFTF."}
	    {:name "SFTF - Loser" :id "sftf_loser" :tip "Most times on losing team for SFTF."}
	    {:name "TDM - Winner" :id "tdm_winner" :tip "Most times on winning team for TDM."}
	    {:name "TDM - Loser" :id "tdm_loser" :tip "Most times on losing team for TDM."}])

	  (= award "bulldozer") (format-award (rank-total-world-damage @game-archive))
	  (= award "broken_ankles") (format-award (rank-total-fall-damage @game-archive))
	  (= award "burning_man") (format-award (rank-self-fire-damage @game-archive))
	  (= award "chatty_cathy") (format-award (rank-num-talks @game-archive))
	  (= award "darwin") (format-award (rank-total-damage-from-world @game-archive))
	  (= award "death_frenzy") (format-award (rank-death-streaks @game-archive))
	  (= award "elusive") (reverse-format-award (rank-kills-plus-deaths @game-archive))
	  (= award "kill_frenzy") (format-award (rank-kill-streaks @game-archive))
	  (= award "lamer") (format-award (rank-num-lame-kills @game-archive))
	  (= award "lemming") (format-award (rank-num-suicides @game-archive))
	  (= award "masochist") (format-award (rank-total-self-damage @game-archive))
	  (= award "scapegoat") (format-award (rank-total-team-dam-received @game-archive))
	  (= award "scavenger") (format-award (rank-num-weapon-pickups @game-archive))
	  (= award "shocker") (format-award (rank-shock-duration @game-archive))
	  (= award "traitor") (format-award (rank-num-team-kills @game-archive))
	  (= award "watery_grave") (format-award (rank-num-water-deaths @game-archive))
	  (= award "wolverine") (format-award (rank-num-item-pickups @game-archive))
	  
	  (= award "artillery") (format-award (rank-artillery-damage @game-archive))
	  (= award "bazooka") (format-award (rank-bazooka-damage @game-archive))
	  (= award "comrade") (format-award (rank-russian-wep-kills @game-archive))
	  (= award "crotch_shot") (format-award (rank-crotch-kills @game-archive))
	  (= award "flamethrower") (format-award (rank-flamethrower-damage @game-archive))
	  (= award "fubar") (format-award (rank-fubar-damage @game-archive))
	  (= award "grenade") (format-award (rank-grenade-damage @game-archive))
	  (= award "heavy_mg") (format-award (rank-heavy-mg-kills @game-archive))
	  (= award "jeep") (format-award (rank-jeep-gun-kills @game-archive))
	  (= award "jeep_crush") (format-award (rank-jeep-crush-damage @game-archive))
	  (= award "light_mg") (format-award (rank-light-mg-kills @game-archive))
	  (= award "limb_shot") (format-award (rank-limb-kills @game-archive))
	  (= award "limey") (format-award (rank-british-wep-kills @game-archive))
	  (= award "marksmanship") (format-award (rank-head-neck-kills @game-archive))
	  (= award "nazi") (format-award (rank-german-wep-kills @game-archive))
	  (= award "pistol") (format-award (rank-pistol-kills @game-archive))
	  (= award "rifle") (format-award (rank-rifle-kills @game-archive))
	  (= award "scorched_earth") (format-award (rank-total-dam-dealt @game-archive))
	  (= award "tank") (format-award (rank-tank-kills @game-archive))
	  (= award "tank_crush") (format-award (rank-tank-crush-damage @game-archive))
	  (= award "yankee") (format-award (rank-american-wep-kills @game-archive))
	  
	  (= award "ctf_agent") (format-award (rank-num-ctf-takes @game-archive))
	  (= award "ctf_conqueror") (format-award (rank-num-ctf-captures @game-archive))
	  (= award "ctf_hero") (format-award (rank-num-ctf-returns @game-archive))
	  (= award "ctf_ranger") (format-award (rank-num-ctf-pickups @game-archive))
	  (= award "ctf_winner") (format-award (rank-num-ctf-wins @game-archive))
	  (= award "ctf_loser") (format-award (rank-num-ctf-losses @game-archive))
	  (= award "dom_agent") (format-award (rank-num-dom-takes @game-archive))
	  (= award "dom_conqueror") (format-award (rank-num-dom-captures @game-archive))
	  (= award "dom_defender") (format-award (rank-num-dom-defends @game-archive))
	  (= award "dom_patriot") (format-award (rank-num-dom-fails @game-archive))
	  (= award "dom_wingman") (format-award (rank-num-dom-assists @game-archive))
	  (= award "dom_winner") (format-award (rank-num-dom-wins @game-archive))
	  (= award "dom_loser") (format-award (rank-num-dom-losses @game-archive))
	  (= award "ftf_agent") (format-award (rank-num-ftf-steals @game-archive))
	  (= award "ftf_conqueror") (format-award (rank-num-ftf-scores @game-archive))
	  (= award "ftf_defender") (format-award (rank-num-ftf-defends @game-archive))
	  (= award "ftf_patriot") (format-award (rank-num-ftf-fails @game-archive))
	  (= award "ftf_wingman") (format-award (rank-num-ftf-assists @game-archive))
	  (= award "ftf_winner") (format-award (rank-num-ftf-wins @game-archive))
	  (= award "ftf_loser") (format-award (rank-num-ftf-losses @game-archive))
	  (= award "sftf_agent") (format-award (rank-num-sftf-steals @game-archive))
	  (= award "sftf_conqueror") (format-award (rank-num-sftf-scores @game-archive))
	  (= award "sftf_defender") (format-award (rank-num-sftf-defends @game-archive))
	  (= award "sftf_patriot") (format-award (rank-num-sftf-fails @game-archive))
	  (= award "sftf_wingman") (format-award (rank-num-sftf-assists @game-archive))
	  (= award "sftf_winner") (format-award (rank-num-sftf-wins @game-archive))
	  (= award "sftf_loser") (format-award (rank-num-sftf-losses @game-archive))
	  (= award "tdm_winner") (format-award (rank-num-tdm-wins @game-archive))
	  (= award "tdm_loser") (format-award (rank-num-tdm-losses @game-archive))
	  
	  :else (str award)))))

(defservice cod-stats-routes)
