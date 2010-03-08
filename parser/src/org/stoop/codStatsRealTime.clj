(ns org.stoop.codStatsRealTime
  (:use org.stoop.codParser org.stoop.codData org.stoop.codIdentity org.stoop.schedule
	clojure.contrib.seq-utils clojure.contrib.str-utils))

;Real time processing
(def game-records (ref []))
(def game-archive (ref []))

(def player-stats-map (ref {}))
(def player-id-ratio-map (ref {}))

(def *transformer* (ref (get-transformer "none")))
(def *current-teams* (ref {:allies "american" :axis "german" :spectator "spectator" :none ""}))

(def *start-time* (ref 0))

(defstruct player-stats :name :photo :place :rank :team :kills :deaths :inflicted :received :trend)

(defn get-player
  "Gets the player's identity using codIdentity and either returns their current stats or creates a
new stats object for them."
  [player-struct]
  (let [player-id (get-player-id (:name player-struct) (:num player-struct))
	player (get @player-stats-map player-id)]
    (if player
      player
      (let [new-player (struct player-stats (:name player-struct)
			       "default.jpg" (count @player-stats-map) 0 "none" 0 0 0 0 "")]
	(dosync (alter player-stats-map assoc player-id new-player))
	(do new-player)))))

(defn update-player 
  "Merges new-stats with the player-stats structure currently associated with the player."
  [player new-stats]
  (dosync (alter player-stats-map assoc (get-player-id (:name player) (:num player))
		 (merge (get-player player) new-stats {:name (:name player)}))))

(defn create-player-update-packet 
  "Creates a map to represent the player packet to send to the front end."
  [player]
  (let [player-team (get @*current-teams* (:team player))]
    (if (nil? player-team)
      (merge {:id (get-player-id (:name player) (:num player))} (get-player player))
      (merge {:id (get-player-id (:name player) (:num player))}
	     (get-player player)
	     (if (not (nil? player-team))
	       {:team (str (first player-team))}
	       {:team ""})))))

(defn process-damage 
  "Increments the inflicted field for attacker and received field for victim by damage."
  [attacker victim damage]
  (let [old-attacker (get-player attacker)
	old-victim (get-player victim)]
    (when (not (= (:team attacker) (:team victim)))
      (update-player attacker (update-in old-attacker [:inflicted] + (int damage))))
    (update-player victim (update-in old-victim [:received] + (int damage)))))

(defn update-places 
  "Recalculates the places for all players based upon current number of kills and sets them in map-ref."
  [map-ref]
  (let [sorted-list (indexed (reverse (sort-by #(:kills (val %)) @map-ref)))]
    (dorun
     (for [player-entry sorted-list]
       (let [player-place (first player-entry)
	     player-id (first (second player-entry))
	     old-player (get @map-ref player-id)]
	 (dosync (alter map-ref assoc player-id (assoc old-player :place (inc player-place)))))))))

(defn calculate-ratio
  "Calculates the ratio of kills over deaths in a player struct"
  [player-struct]
  (if (= 0 (:deaths player-struct))
    1.0
    (/ (:kills player-struct) (:deaths player-struct))))

(defn get-ratio-trend
  "Determines if a new ratio is flat (\"\"), trending upward(+) or trending downward(-)."
  [new-ratio old-ratio]
  (cond
   (nil? old-ratio) ""
   (> new-ratio old-ratio) "+"
   (= new-ratio old-ratio) ""
   (< new-ratio old-ratio) "-"))

(defn update-ratios
  "Updates the ratios for all players in the stats-ref map and the 'old' ratios in ratio-ref map."
  [stats-ref ratio-ref]
  (dorun
   (for [player-entry @stats-ref]
    (let [player-id (first player-entry)
	  old-ratio (get @ratio-ref player-id)
	  old-player (get @stats-ref player-id)
	  new-ratio (calculate-ratio old-player)
	  ratio-trend (get-ratio-trend new-ratio old-ratio)]
      (dosync (alter ratio-ref assoc player-id new-ratio)
	      (alter stats-ref assoc player-id (assoc old-player :trend ratio-trend)))))))

(defn process-kill 
  "Increments kills for attacker and deaths for victim.  Kills is not incremented for self kills.
Also adds a map packet indicating the location of the kills and player update packets for both the attacker
and victim to be sent to the frontend."
  [attacker victim kx ky dx dy weapon x-transformer y-transformer]
  (let [old-attacker (get-player attacker)
	old-victim (get-player victim)
        trans-kx (x-transformer kx ky)
	trans-ky (y-transformer kx ky)
	trans-dx (x-transformer dx dy)
	trans-dy (y-transformer dx dy)]
    ;Update kills and deaths
    (update-player attacker (update-in old-attacker [:kills] inc))
    (update-player victim (update-in old-victim [:deaths] inc))
    ;Update team values
    (update-player attacker {:team (:team attacker)})
    (update-player victim {:team (:team victim)})
    ;Update stats and game records
    (update-places player-stats-map)
    (dosync (alter game-records conj
		   {:kx trans-kx :ky trans-ky :dx trans-dx :dy trans-dy
		    :kname (:name attacker) :kteam (:team attacker)
		    :dname (:name victim) :dteam (:team victim)
		    :weapon weapon}
		   (create-player-update-packet attacker)
		   (create-player-update-packet victim)))))

(defn process-suicide
  "Increments deaths for suicide victim."
  [victim sx sy weapon x-transformer y-transformer]
  (let [old-victim (get-player victim)
	trans-sx (x-transformer sx sy)
	trans-sy (y-transformer sx sy)]
    (update-player victim (update-in old-victim [:deaths] inc))
    (update-player victim {:team (:team victim)})
    (update-places player-stats-map)
    (dosync (alter game-records conj
		   {:sx trans-sx :sy trans-sy 
		    :sname (:name victim) :steam (:team victim)
		    :weapon weapon}
		   (create-player-update-packet victim)))))

;Update to archive game-records for whole match stats calculation
(defn process-start-game 
  "Sets the data for the frontend to a game start packet, resets player stats records and resets the start
time for this game."
  [game-type map-name round-time allies-team axis-team time-stamp]
  (dosync (ref-set game-records [{:map map-name :type game-type :time round-time}
				 {:time 0}])
	  (ref-set player-stats-map {})
	  (ref-set *start-time* time-stamp)
	  (ref-set *transformer* (get-transformer map-name))
	  (ref-set *current-teams* {:allies allies-team :axis axis-team :spectator "spectator"})
	  (ref-set player-id-ratio-map {})))

(defn process-game-event
  "Adds an event packet to the data to be sent to the frontend."
  [team time-stamp]
  (if (= team :none)
    (dosync (alter game-records conj {:time (- time-stamp @*start-time*)}))
    (dosync (alter game-records conj {:team (str (first (get @*current-teams* (keyword team))))
				      :time (- time-stamp @*start-time*)}))))

(defn heartbeat-game-event
  "Takes a log-entry, extracts the time stamp and generates a game event with team of none and the time stamp."
  [log-entry]
  (when (not (nil? (get log-entry :time)))
      (process-game-event :none (:time log-entry))))

(defn process-spectator-event
  [player]
  (do
    (update-player player {:team :spectator})
    (dosync (alter game-records conj (create-player-update-packet player)))))

(defn process-rank-event
  [player new-rank]
  (update-player player {:rank new-rank}))

(defn process-quit-event
  [player]
  (do
    (update-player player {:team :none})
    (dosync (alter game-records conj (create-player-update-packet player)))
    (next-ip (:num player))))

(defn store-game-record
  [game-record]
  (dosync (alter game-archive conj game-record)))

(defn resolve-player-id
  "Searches through a game record and updates the :id field of player maps to their current ID."
  [record]
  (cond 
   (player? record) (inject-player-id record)
   
   (map? record)
   (reduce merge (for [key-val record]
		   (hash-map (key key-val) (resolve-player-id (val key-val)))))
   
   (vector? record)
   (vec (for [item record]
	  (resolve-player-id item)))

   :else
   record))

(defn process-input-line
  "Parses the input-line and then determines how to process the parsed input."
  [input-line]
  (let [parsed-input (parse-line input-line)]
    (when (not (nil? parsed-input))
      (store-game-record (resolve-player-id parsed-input))
      (cond
       (start-game? (parsed-input :entry))
       (process-start-game (get-in parsed-input [:entry :game-type])
			   (get-in parsed-input [:entry :map-name])
			   (get-in parsed-input [:entry :round-time])
			   (get-in parsed-input [:entry :allies-team])
			   (get-in parsed-input [:entry :axis-team])
			   (get parsed-input :time))

       (damage-kill? (parsed-input :entry))
       (do
	 (process-damage (get-in parsed-input [:entry :attacker])
			 (get-in parsed-input [:entry :victim])
			 (get-in parsed-input [:entry :hit-details :damage]))
	 (cond
	  (suicide? (parsed-input :entry))
	  (process-suicide (get-in parsed-input [:entry :victim])
			   (get-in parsed-input [:entry :victim-loc :x])
			   (get-in parsed-input [:entry :victim-loc :y])
			   (get-in parsed-input [:entry :hit-details :weapon])
			   (get @*transformer* :x)
			   (get @*transformer* :y))

	  (kill? (parsed-input :entry))
	  (process-kill (get-in parsed-input [:entry :attacker])
			(get-in parsed-input [:entry :victim])
			(get-in parsed-input [:entry :attacker-loc :x])
			(get-in parsed-input [:entry :attacker-loc :y])
			(get-in parsed-input [:entry :victim-loc :x])
			(get-in parsed-input [:entry :victim-loc :y])
			(get-in parsed-input [:entry :hit-details :weapon])
			(get @*transformer* :x)
			(get @*transformer* :y))))
      
       (game-event? (parsed-input :entry))
       (process-game-event (get-in parsed-input [:entry :player :team])
			   (get parsed-input :time))
      
       (spectator? (parsed-input :entry))
       (process-spectator-event (get-in parsed-input [:entry :spectator]))

       (rank? (parsed-input :entry))
       (process-rank-event (get-in parsed-input [:entry :player])
			   (get-in parsed-input [:entry :rank]))

       (quit? (parsed-input :entry))
       (process-quit-event (get-in parsed-input [:entry :player]))))))

(def last-ip (ref nil))

(defn process-connect-line
  "Parses the input-line and stores the IP address records if it's a valid line."
  [input-line]
  (let [parsed-input (parse-connect-line input-line)]
    (when parsed-input
      (cond
       (contains? parsed-input :ip-address)
       (dosync (ref-set last-ip (:ip-address parsed-input)))

       (contains? parsed-input :client-id)
       (do (associate-client-id-to-ip (:client-id parsed-input) @last-ip)
	   (dosync (ref-set last-ip nil)))))))

(defn process-file
  [file line-process-function]
  (doseq [line (re-split #"[\r*\n]+" (slurp file))]
    (line-process-function line)))