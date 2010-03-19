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
	      {:name "Value" :type "number"}]
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
       (map #(str % "\n") @game-archive))

  (GET "/stats/photo"
       (let [ip-address (:remote-addr request)
	     photo (:set params)]
	 (when (not (nil? photo))
	   (set-photo ip-address photo)
	   (str "Photo set to " photo " for " ip-address))))

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
	    {:name "Elusive" :id "elusive" :tip "Lowest kills plus deaths."}
	    {:name "Lemming" :id "lemming" :tip "Most deaths by suicide."}
	    {:name "Masochist" :id "masochist" :tip "Most self-inflicted damage."}
	    {:name "Scapegoat" :id "scapegoat" :tip "Most damage received from teammates."}
	    {:name "Scavenger" :id "scavenger" :tip "Most weapon pickups."}
	    {:name "The Shocker" :id "shocker" :tip "Most time spent shell shocked."}
	    {:name "Traitor" :id "traitor" :tip "Most team kills."}
	    {:name "Wolverine" :id "wolverine" :tip "Most health pickups."}
	    {:name "Artillery" :id "artillery" :tip "Most damage done by artillery weapons."}
	    {:name "Bazooka" :id "bazooka" :tip "Most damage done by bazooka."}
	    {:name "Comrade" :id "comrade" :tip "Most kills by Russian weapons."}
	    {:name "Flamethrower" :id "flamethrower" :tip "Most damage done by flamethrower."}
	    {:name "FUBAR" :id "fubar" :tip "Most damage done by FUBAR weapons."}
	    {:name "Grenade" :id "grenade" :tip "Most damage done by grenades."}
	    {:name "Heavy Machine Gun" :id "heavy_mg" :tip "Most kills by heavy machine gun."}
	    {:name "Jeep" :id "jeep" :tip "Most kills by mounted jeep gun."}
	    {:name "Light Machine Gun" :id "light_mg" :tip "Most kills by light machine gun."}
	    {:name "Limey" :id "limey" :tip "Most kills by British weapons."}
	    {:name "Nazi" :id "nazi" :tip "Most kills by German weapons."}
	    {:name "Pistol" :id "pistol" :tip "Most kills by pistol."}
	    {:name "Rifle" :id "rifle" :tip "Most kills by rifle."}
	    {:name "Tank" :id "tank" :tip "Most kills by tank."}
	    {:name "Yankee" :id "yankee" :tip "Most kills by American weapons."}])

	  (= award "bulldozer") (format-award (rank-total-world-damage @game-archive))
	  (= award "broken_ankles") (format-award (rank-total-fall-damage @game-archive))
	  (= award "burning_man") (format-award (rank-self-fire-damage @game-archive))
	  (= award "chatty_cathy") (format-award (rank-num-talks @game-archive))
	  (= award "darwin") (format-award (rank-total-damage-from-world @game-archive))
	  (= award "elusive") (format-award (reverse (rank-kills-plus-deaths @game-archive)))
	  (= award "lemming") (format-award (rank-num-suicides @game-archive))
	  (= award "masochist") (format-award (rank-total-self-damage @game-archive))
	  (= award "scapegoat") (format-award (rank-total-team-dam-received @game-archive))
	  (= award "scavenger") (format-award (rank-num-weapon-pickups @game-archive))
	  (= award "shocker") (format-award (rank-shock-duration @game-archive))
	  (= award "traitor") (format-award (rank-num-team-kills @game-archive))
	  (= award "wolverine") (format-award (rank-num-item-pickups @game-archive))
	  
	  (= award "artillery") (format-award (rank-artillery-damage @game-archive))
	  (= award "bazooka") (format-award (rank-bazooka-kills @game-archive))
	  (= award "comrade") (format-award (rank-russian-wep-kills @game-archive))
	  (= award "flamethrower") (format-award (rank-flamethrower-damage @game-archive))
	  (= award "fubar") (format-award (rank-fubar-damage @game-archive))
	  (= award "grenade") (format-award (rank-grenade-damage @game-archive))
	  (= award "heavy_mg") (format-award (rank-heavy-mg-kills @game-archive))
	  (= award "jeep") (format-award (rank-jeep-gun-kills @game-archive))
	  (= award "light_mg") (format-award (rank-light-mg-kills @game-archive))
	  (= award "limey") (format-award (rank-british-wep-kills @game-archive))
	  (= award "nazi") (format-award (rank-german-wep-kills @game-archive))
	  (= award "pistol") (format-award (rank-pistol-kills @game-archive))
	  (= award "rifle") (format-award (rank-rifle-kills @game-archive))
	  (= award "tank") (format-award (rank-tank-kills @game-archive))
	  (= award "yankee") (format-award (rank-american-wep-kills @game-archive))

	  :else (str award)))))

(defservice cod-stats-routes)
