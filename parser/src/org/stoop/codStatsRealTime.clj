(ns org.stoop.codStatsRealTime
  (:use org.stoop.codParser org.stoop.codData
	clojure.contrib.seq-utils))

;Real time processing

(def *game-records* (ref []))
(def *player-stats-map* (ref {}))

(def *start-time* (ref (. System currentTimeMillis)))
(defn calc-seconds [start-time-millis end-time-millis]
  (int (* 0.001 (- end-time-millis start-time-millis))))

;Need some kind of storage for the records as they come in.
;Possibly store based upon the type of record?
;Might as well go with the cached method.  So as data comes in, add it to a data set to be processed.
;During processing, compute the stats for the current "new" data set.
;Update the old stats based upon the new
;Store the just processed "new" data in the "old" data set.
;When a new game starts, reset the current stats and archive out the "old" data set.

(defstruct player-stats :name :photo :place :rank :team :kills :deaths :inflicted :received)

(defn get-player [player-struct]
  (let [player (get @*player-stats-map* (:id player-struct))]
    (if player
      (do player)
      (let [new-player (struct player-stats (:name player-struct) 
			       "default.jpg" (inc (count @*player-stats-map*)) 0 "none" 0 0 0 0)]
	(dosync (alter *player-stats-map* assoc (:id player-struct) new-player))
	(do new-player)))))

(defn create-player-update-packet [player]
  {:type "player"
   :data [(merge {:update (:id player)} (get-player player))]})

(defn update-player [player new-stats]
  (dosync (alter *player-stats-map* assoc (:id player) new-stats)))

(defn process-damage [attacker victim damage]
  (let [old-attacker (get-player attacker)
	old-victim (get-player victim)]
    (update-player attacker (assoc old-attacker :inflicted (+ (old-attacker :inflicted) damage)))
    (update-player victim (assoc old-victim :received (+ (old-victim :received) damage)))))

;Need to update place upon each kill
(defn process-kill [attacker victim kx ky dx dy x-transformer y-transformer]
  (let [old-attacker (get-player attacker)
	old-victim (get-player victim)
        trans-kx (x-transformer kx ky)
	trans-ky (y-transformer kx ky)
	trans-dx (x-transformer dx dy)
	trans-dy (y-transformer dx dy)]
    (update-player attacker (assoc old-attacker :kills (inc (old-attacker :kills))))
    (update-player victim (assoc old-victim :deaths (inc (old-victim :deaths))))
    (dosync (alter *game-records* conj 
		   {:kx trans-kx :ky trans-ky :dx trans-dx :dy trans-dy}
		   (create-player-update-packet attacker)
		   (create-player-update-packet victim)))))

;Update to archive game-records for whole match stats calculation
(defn process-start-game [game-type map-name round-time]
  (dosync (ref-set *game-records* [{:map map-name :type game-type :time round-time}])
	  (ref-set *player-stats-map* {})
	  (ref-set *start-time* (. System currentTimeMillis))))

;Don't have an obvious way to distinguish between american, british and russian
(defn process-game-event [team]
  (dosync (alter *game-records* conj {:team team 
				      :time (calc-seconds @*start-time* (. System currentTimeMillis))})))

(defn process-input-line [input-line]
  (let [parsed-input (parse-line input-line)]
    ;if this is a new-game record reset game-records
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
	  (do
	    (process-kill (get-in parsed-input [:entry :attacker])
			  (get-in parsed-input [:entry :victim])
			  (get-in parsed-input [:entry :attacker-loc :x])
			  (get-in parsed-input [:entry :attacker-loc :y])
			  (get-in parsed-input [:entry :victim-loc :x])
			  (get-in parsed-input [:entry :victim-loc :y])
			  carentan-x-transformer
			  carentan-y-transformer))))
      
      (game-event? (parsed-input :entry))
      (process-game-event (get-in parsed-input [:entry :player :team])))))

;process-parsed-input
;if this is a damage-kill record
  ;find-player attacker & victim
    ;if name changed, update player name
    ;if team changed, reset stats - handle in spawn case
    ;if new-player, add new player to stats set
    ;return player
  ;update attacker inflicted and victim received
  ;if this is a kill-record
    ;update attacker kills and victim deaths
    ;recalculate places
  ;if this is a rank-change record
    ;update attacker rank
;if this is a quit record
  ;remove player from stats set?