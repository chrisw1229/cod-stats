(ns org.stoop.codStatsRealTime
  (:use org.stoop.codParser org.stoop.parser org.stoop.codData
	clojure.contrib.seq-utils))

;Temporary, need to update my clojure-contrib
(defn positions [pred coll]
  (for [[idx elt] (indexed coll) :when (pred elt)] idx))

;Real time processing

(def *game-records* (ref []))
(def *player-stats-records* (ref []))

;Need some kind of storage for the records as they come in.
;Possibly store based upon the type of record?
;Might as well go with the cached method.  So as data comes in, add it to a data set to be processed.
;During processing, compute the stats for the current "new" data set.
;Update the old stats based upon the new
;Store the just processed "new" data in the "old" data set.
;When a new game starts, reset the current stats and archive out the "old" data set.

;photo - Where do i get this?
(defstruct player-stats :name :photo :place :rank :team :kills :deaths :inflicted :received)

(defn get-player [name records-ref]
  (let [player (filter #(= name (% :name)) @records-ref)]
    (if (> (count player) 0)
      (first player)
      (let [new-player (struct player-stats name "default.jpg" (+ 1 (count @records-ref)) 0 "none" 0 0 0 0)]
	(dosync (ref-set records-ref (conj @records-ref new-player)))
	(do new-player)))))

(defn get-player-index [name records]
  (first (positions #(= name (% :name)) records)))

(defn replace-player [name new-stats records-ref]
  (dosync (ref-set records-ref (assoc @records-ref (get-player-index name @records-ref) new-stats))))

(defn process-damage [attacker victim damage]
  (let [old-attacker (get-player attacker *player-stats-records*)
	old-victim (get-player victim *player-stats-records*)]
    (replace-player attacker 
		    (assoc old-attacker :inflicted (+ (old-attacker :inflicted) damage)) *player-stats-records*)
    (replace-player victim 
		    (assoc old-victim :received (+ (old-victim :received) damage)) *player-stats-records*)))

(defn process-kill [attacker victim kx ky dx dy x-transformer y-transformer]
  (let [old-attacker (get-player attacker *player-stats-records*)
	old-victim (get-player victim *player-stats-records*)
        trans-kx (x-transformer kx ky)
	trans-ky (y-transformer kx ky)
	trans-dx (x-transformer dx dy)
	trans-dy (y-transformer dx dy)]
    (replace-player attacker (assoc old-attacker :kills (inc (old-attacker :kills))) *player-stats-records*)
    (replace-player victim (assoc old-victim :deaths (inc (old-victim :deaths))) *player-stats-records*)
    (dosync (ref-set *game-records* (conj @*game-records* {:kx trans-kx :ky trans-ky :dx trans-dx :dy trans-dy})))))

;Update to archive game-records for whole match stats calculation
(defn process-start-game [game-type map-name round-time]
  (dosync (ref-set *game-records* [{:map map-name :type game-type :time round-time}])))

;Update to use timer to set time in minutes for :time
;Don't have an obvious way to distinguish between american, british and russian
(defn process-game-event [team]
  (dosync (ref-set *game-records* (conj @*game-records* {:team team :time 0}))))

(defn process-input-line [input-line]
  (let [parsed-input (parse input-line log-line)]
    ;if this is a new-game record reset game-records
    (cond
      (start-game? (parsed-input :entry))
      (process-start-game (get-in parsed-input [:entry :game-type])
			  (get-in parsed-input [:entry :map-name])
			  (get-in parsed-input [:entry :round-time]))

      (damage-kill? (parsed-input :entry))
      (do
	(process-damage (get-in parsed-input [:entry :attacker :name])
			(get-in parsed-input [:entry :victim :name])
			(get-in parsed-input [:entry :hit-details :damage]))
	;Handle case of no location data as well
	(if (kill? (parsed-input :entry))
	  (do
	    (process-kill (get-in parsed-input [:entry :attacker :name])
			  (get-in parsed-input [:entry :victim :name])
			  (get-in parsed-input [:entry :attacker-loc :x])
			  (get-in parsed-input [:entry :attacker-loc :y])
			  (get-in parsed-input [:entry :victim-loc :x])
			  (get-in parsed-input [:entry :victim-loc :y])
			  carentan-x-transformer
			  carentan-y-transformer))))
      (game-event? (parsed-input :entry))
      (process-game-event (get-in parsed-input [:entry :player :team])
			  (get-in parsed-input [:entry :event])))))

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