(ns org.stoop.codStatsRealTime
  (:use org.stoop.codParser org.stoop.codData org.stoop.codIdentity
	clojure.contrib.seq-utils))

;Real time processing

(defn timed-action
  "Calls a function f every interval seconds with arguments rest"
  [interval f & rest]
  (let [keep-running (atom true)
	thread (Thread. #(while @keep-running
			   (do
			     (f rest)
			     (Thread/sleep (* 1000 interval)))))]
    {:start #(.start thread)
     :stop #(do (reset! keep-running false)
		(.join thread))}))

(def *player-id-ratio-map* (ref {}))

(def *game-records* (ref []))
(def *player-stats-map* (ref {}))
(def *transformer* (ref (get-transformer "none")))
(def *current-teams* (ref {:allies "american" :axis "german"}))

(def *start-time* (ref (. System currentTimeMillis)))
(defn calc-seconds [start-time-millis end-time-millis]
  (int (* 0.001 (- end-time-millis start-time-millis))))

(defstruct player-stats :name :photo :place :rank :team :kills :deaths :inflicted :received :ratio)

(defn get-player
  "Currently pulls the player's client id out of the player-struct and either returns the stats
entry or creates a new entry and returns that."
  [player-struct]
  (let [player-id (get-player-id (:name player-struct) (:id player-struct))
	player (get @*player-stats-map* player-id)]
    (if player
      (do player)
      (let [new-player (struct player-stats (:name player-struct)
			       "default.jpg" (count @*player-stats-map*) 0 "none" 0 0 0 0 "")]
	(dosync (alter *player-stats-map* assoc player-id new-player)
		(alter *player-id-ratio-map* assoc player-id 0))
	(do new-player)))))

(defn update-player 
  "Merges new-stats with the player-stats structure currently associated with the player."
  [player new-stats]
  (dosync (alter *player-stats-map* assoc (get-player-id (:name player) (:id player))
		 (merge (get-player player) new-stats))))

(defn create-player-update-packet 
  "Creates a map to represent the player packet to send to the front end."
  [player]
  (merge {:id (get-player-id (:name player) (:id player))} (get-player player)))

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
	      (alter stats-ref assoc player-id (assoc old-player :ratio ratio-trend)))))))

(def *ratio-calculator* (timed-action 60 update-ratios *player-stats-map* *player-id-ratio-map*))

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

(defn process-connect-line
  "Parses the input-line and updates the IP address records if its a valid line."
  [input-line]
  (let [parsed-input (parse-connect-line input-line)]
    (when parsed-input
      (associate-client-id-to-ip (:client-id parsed-input) (:ip-address parsed-input)))))