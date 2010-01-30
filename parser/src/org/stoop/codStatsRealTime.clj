(ns org.stoop.codStatsRealTime
  (:use org.stoop.codParser org.stoop.codData
	clojure.contrib.seq-utils))

;Real time processing

(def *game-records* (ref []))
(def *player-stats-map* (ref {}))

(def *start-time* (ref (. System currentTimeMillis)))
(defn calc-seconds [start-time-millis end-time-millis]
  (int (* 0.001 (- end-time-millis start-time-millis))))

(defstruct player-stats :name :photo :place :rank :team :kills :deaths :inflicted :received)

(defn get-player 
  "Currently pulls the player's client id out of the player-struct and either returns the stats
entry or creates a new entry and returns that."
  [player-struct]
  (let [player (get @*player-stats-map* (:id player-struct))]
    (if player
      (do player)
      (let [new-player (struct player-stats (:name player-struct) 
			       "default.jpg" (inc (count @*player-stats-map*)) 0 "none" 0 0 0 0)]
	(dosync (alter *player-stats-map* assoc (:id player-struct) new-player))
	(do new-player)))))

(defn create-player-update-packet 
  "Creates a map to represent the player packet to send to the front end."
  [player]
  (merge {:id (:id player)} (get-player player)))

(defn update-player 
  "Merges new-stats with the player-stats structure currently associated with the player."
  [player new-stats]
  (dosync (alter *player-stats-map* assoc (:id player) (merge (get-player player) new-stats))))

(defn process-damage 
  "Increments the inflicted field for attacker and received field for victim by damage."
  [attacker victim damage]
  (let [old-attacker (get-player attacker)
	old-victim (get-player victim)]
    (update-player attacker {:inflicted (+ (old-attacker :inflicted) damage)})
    (update-player victim {:received (+ (old-victim :received) damage)})))

(defn update-places 
  "Recalculates the places for all players based upon current number of kills and sets them in map-ref."
  [map-ref]
  (let [sorted-list (indexed (reverse (sort-by #(:kills (val %)) @map-ref)))]
    (doall
     (for [player-entry sorted-list]
       (let [player-place (first player-entry)
	     player-id (first (second player-entry))
	     old-player (get @map-ref player-id)]
	 (dosync (alter map-ref assoc player-id (assoc old-player :place (inc player-place)))))))))

(defn process-kill 
  "Increments kills for attacker and deaths for victim.  Kills is not incremented for self kills.
Also adds a map packet indicating the location of the kills and player update packets for both the attacker
and victim to be sent to the frontend."
  [attacker victim kx ky dx dy x-transformer y-transformer]
  (let [old-attacker (get-player attacker)
	old-victim (get-player victim)
        trans-kx (x-transformer kx ky)
	trans-ky (y-transformer kx ky)
	trans-dx (x-transformer dx dy)
	trans-dy (y-transformer dx dy)]
    (when (not (= (:name attacker) (:name victim)))
      (update-player attacker {:kills (inc (old-attacker :kills))}))
    (update-player victim {:deaths (inc (old-victim :deaths))})
    (update-places *player-stats-map*)
    (dosync (alter *game-records* conj
		   {:kx trans-kx :ky trans-ky :dx trans-dx :dy trans-dy}
		   (create-player-update-packet attacker)
		   (create-player-update-packet victim)))))

;Update to archive game-records for whole match stats calculation
;Update to switch x and y transformers to correct map.
(defn process-start-game 
  "Sets the data for the frontend to a game start packet, resets player stats records and resets the start
time for this game."
  [game-type map-name round-time]
  (dosync (ref-set *game-records* [{:map map-name :type game-type :time round-time}])
	  (ref-set *player-stats-map* {})
	  (ref-set *start-time* (. System currentTimeMillis))))

;Don't have an obvious way to distinguish between american, british and russian
(defn process-game-event 
  "Adds an event packet to the data to be sent to the frontend."
  [team]
  (dosync (alter *game-records* conj {:team team 
				      :time (calc-seconds @*start-time* (. System currentTimeMillis))})))

(defn process-input-line
  "Parses the input-line and then determines how to process the parsed input."
  [input-line]
  (let [parsed-input (parse-line input-line)]
    (cond
      (start-game? (parsed-input :entry))
      (process-start-game (get-in parsed-input [:entry :game-type])
			  (get-in parsed-input [:entry :map-name])
			  (get-in parsed-input [:entry :round-time]))

      (damage-kill? (parsed-input :entry))
      (do
	(process-damage (get-in parsed-input [:entry :attacker])
			(get-in parsed-input [:entry :victim])
			(get-in parsed-input [:entry :hit-details :damage]))
	;Handle case of no location data as well
	(if (kill? (parsed-input :entry))
	  (process-kill (get-in parsed-input [:entry :attacker])
			(get-in parsed-input [:entry :victim])
			(get-in parsed-input [:entry :attacker-loc :x])
			(get-in parsed-input [:entry :attacker-loc :y])
			(get-in parsed-input [:entry :victim-loc :x])
			(get-in parsed-input [:entry :victim-loc :y])
			carentan-x-transformer
			carentan-y-transformer)))
      
      (game-event? (parsed-input :entry))
      (process-game-event (get-in parsed-input [:entry :player :team])))))