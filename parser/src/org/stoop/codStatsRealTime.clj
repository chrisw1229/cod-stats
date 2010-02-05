(ns org.stoop.codStatsRealTime
  (:use org.stoop.codParser org.stoop.codData
	clojure.contrib.seq-utils))

;Real time processing

(def *game-records* (ref []))
(def *player-stats-map* (ref {}))

(def *player-id-map* (ref {}))
(def *name-id-map* (ref {}))
(def *client-id-id-map* (ref {}))
(def *new-id* (ref 1))

(def *transformer* (ref {:x nil :y nil}))
(def *current-teams* (ref {:allies "american" :axis "german"}))

(def *start-time* (ref (. System currentTimeMillis)))
(defn calc-seconds [start-time-millis end-time-millis]
  (int (* 0.001 (- end-time-millis start-time-millis))))

;Add trend (values of +, - or "") - Recalc initially at 30-60 secs
(defstruct player-stats :name :photo :place :rank :team :kills :deaths :inflicted :received)

(defn create-new-player-id [name client-id]
  "Creates a new player ID to associate with name/client-id pair."
  (dosync (alter *player-id-map* assoc [name client-id] @*new-id*)
	  (alter *name-id-map* assoc name @*new-id*)
	  (alter *client-id-id-map* assoc client-id @*new-id*)
	  (alter *new-id* inc))
  (dec @*new-id*))

(defn get-player-id
  "Gets the current id associated with name/client-id combination.

If the name/client-id pair is not associated with an ID, a search will be done first to see if there is
an ID that has been associated with the name and that will be returned along with associating the current
name/client-id pair to that ID.

If no ID is associated with the name, a search will be done to see if there is an ID that is associated
with the client-id and that ID will be returned along with associating the current name/client-id pair to
that ID.

If no name or client-id is found to be a match, a new ID will be generated and associated with the
client-id/name pair."
  [name client-id]
  (let [player-id (get @*player-id-map* [name client-id])]
    (if player-id
      (do player-id)
      (let [player-id (get @*name-id-map* name)]
	(if player-id
	  (do (dosync (alter *player-id-map* assoc [name client-id] player-id)
		      (alter *client-id-id-map* assoc client-id player-id)) 
	      player-id)
	  (let [player-id (get @*client-id-id-map* client-id)]
	    (if player-id
	      (do (dosync (alter *player-id-map* assoc [name client-id] player-id)
			  (alter *player-id-map* assoc name player-id)) 
		  player-id)
	      (create-new-player-id name client-id))))))))

(defn get-player
  "Currently pulls the player's client id out of the player-struct and either returns the stats
entry or creates a new entry and returns that."
  [player-struct]
  (let [player-id (get-player-id (:name player-struct) (:id player-struct))
	player (get @*player-stats-map* player-id)]
    (if player
      (do player)
      (let [new-player (struct player-stats (:name player-struct)
			       "default.jpg" (count @*player-stats-map*) 0 "none" 0 0 0 0)]
	(dosync (alter *player-stats-map* assoc player-id new-player))
	(do new-player)))))

(defn create-player-update-packet 
  "Creates a map to represent the player packet to send to the front end."
  [player]
  (merge {:id (get-player-id (:name player) (:id player))} (get-player player)))

(defn update-player 
  "Merges new-stats with the player-stats structure currently associated with the player."
  [player new-stats]
  (dosync (alter *player-stats-map* assoc (get-player-id (:name player) (:id player))
		 (merge (get-player player) new-stats))))

(defn process-damage 
  "Increments the inflicted field for attacker and received field for victim by damage."
  [attacker victim damage]
  (let [old-attacker (get-player attacker)
	old-victim (get-player victim)]
    (update-player attacker (update-in old-attacker [:inflicted] + damage))
    (update-player victim (update-in old-victim [:received] + damage))))

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
      (update-player attacker (update-in old-attacker [:kills] inc)))
    (update-player victim (update-in old-victim [:deaths] inc))
    (update-places *player-stats-map*)
    (dosync (alter *game-records* conj
		   {:kx trans-kx :ky trans-ky :dx trans-dx :dy trans-dy}
		   (create-player-update-packet attacker)
		   (create-player-update-packet victim)))))

;Update to archive game-records for whole match stats calculation
(defn process-start-game 
  "Sets the data for the frontend to a game start packet, resets player stats records and resets the start
time for this game."
  [game-type map-name round-time allies-team axis-team]
  (dosync (ref-set *game-records* [{:map map-name :type game-type :time round-time}])
	  (ref-set *player-stats-map* {})
	  (ref-set *start-time* (. System currentTimeMillis))
	  (ref-set *transformer* (get-transformer map-name))
	  (ref-set *current-teams* {:allies allies-team :axis axis-team})))

(defn process-game-event 
  "Adds an event packet to the data to be sent to the frontend."
  [team]
  (dosync (alter *game-records* conj {:team (str (first (get @*current-teams* (keyword team))))
				      :time (calc-seconds @*start-time* (. System currentTimeMillis))})))

(defn process-input-line
  "Parses the input-line and then determines how to process the parsed input."
  [input-line]
  (let [parsed-input (parse-line input-line)]
    (cond
      (start-game? (parsed-input :entry))
      (process-start-game (get-in parsed-input [:entry :game-type])
			  (get-in parsed-input [:entry :map-name])
			  (get-in parsed-input [:entry :round-time])
			  (get-in parsed-input [:entry :allies-team])
			  (get-in parsed-input [:entry :axis-team]))

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
			(get @*transformer* :x)
			(get @*transformer* :y))))
      
      (game-event? (parsed-input :entry))
      (process-game-event (get-in parsed-input [:entry :player :team])))))