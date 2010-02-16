(ns org.stoop.codParser
  (:use clojure.contrib.str-utils clojure.contrib.monads))

(defn is-int? [strn]
  (when (not (nil? strn))
    (try (Integer/parseInt strn)
	 (catch NumberFormatException nfe false))))

(defn is-float? [strn]
  (when (not (nil? strn))
    (try (Float/parseFloat strn)
	 (catch NumberFormatException nfe false))))

(defn is-team? [strn]
  (contains? #{"allies" "axis" "all"} strn))

(defn string-to-team [strn]
  (cond
    (= "allies" strn) :allies
    (= "axis" strn) :axis
    (= "all" strn) :all))

(defn get-team [str-seq]
  (when (> (count str-seq) 0)
    [(string-to-team (first str-seq)) (rest str-seq)]))

(defn get-person [str-seq]
  (when (>= (count str-seq) 2)
    (let [[a b c d] str-seq]
      (cond
	(and (is-int? a) (is-int? b) (is-team? c) (not (nil? d)))
	[{:id a :num b :team (string-to-team c) :name d} (drop 4 str-seq)]
	
	(and (is-int? a) (is-int? b) (not (nil? c)))
	[{:id a :num b :team :none :name c} (drop 3 str-seq)]
	
	(and (is-int? a) (not (nil? b)))
	[{:id :none :num a :team :none :name b} (drop 2 str-seq)]))))

(defn get-people [str-seq]
  (loop [arg-list str-seq
	 people []]
    (if (>= (count arg-list) 2)
      (let [[person remainder] (get-person arg-list)]
	(recur remainder (conj people person)))
      [people arg-list])))

(defn get-string [str-seq]
  (when (> (count str-seq) 0)
    [(first str-seq) (rest str-seq)]))

(defn get-int [str-seq]
  (if (is-int? (first str-seq))
    [(Integer/parseInt (first str-seq)) (rest str-seq)]))

(defn get-float [str-seq]
  (if (is-float? (first str-seq))
    [(Float/parseFloat (first str-seq)) (rest str-seq)]))

(defn get-location [str-seq]
  (when (> (count str-seq) 0)
    (let [[x y z] (map #(Float/parseFloat %) (re-split #"," (first str-seq)))]
      [{:x x :y y :z z} (rest str-seq)])))

(def get-hit-info (domonad state-m
			   [weapon get-string
			    damage get-float
			    type get-string
			    area get-string]
			   {:weapon weapon :damage damage :type type :area area}))

(def get-shell-shock (domonad state-m
			      [_ get-string
			       shocked-player get-person
			       shock-info get-hit-info]
			      {:shock shocked-player :shock-info shock-info}))
  

(def get-spectator (domonad state-m
			    [_ get-string
			     spec-player get-person]
			    {:spectator spec-player}))

(def get-rank (domonad state-m
		       [_ get-string
			rank-player get-person
			new-rank get-int]
		       {:player rank-player :rank new-rank}))

(def get-spawn (domonad state-m
			[_ get-string
			 spawn get-person
			 weapon get-string
			 location get-location]
			{:spawn spawn :weapon weapon :location location}))

(defn get-damage-kill [str-seq]
  (when (> (count str-seq) 0)
    (cond
      (= "K" (first str-seq)) [:kill (rest str-seq)]
      (= "D" (first str-seq)) [:damage (rest str-seq)])))

(def get-dk (domonad state-m
		     [pain-type get-damage-kill
		      victim get-person
		      attacker get-person
		      hit-details get-hit-info
		      victim-loc get-location
		      attacker-loc get-location
		      victim-angle get-float
		      attacker-angle get-float
		      victim-stance get-string
		      attacker-stance get-string]
		     {:type pain-type :victim victim :attacker attacker :hit-details hit-details
		      :victim-loc victim-loc :attacker-loc attacker-loc
		      :victim-angle victim-angle :attacker-angle attacker-angle
		      :victim-stance victim-stance :attacker-stance attacker-stance}))

(def get-vehicle (domonad state-m
			  [vehicle-num get-int
			   vehicle-team get-team
			   vehicle-type get-string
			   vehicle-seat get-int]
			  {:vehicle vehicle-type :id vehicle-num :team vehicle-team :seat vehicle-seat}))

(def get-use-vehicle (domonad state-m
			      [_ get-string
			       user get-person
			       vehicle get-vehicle
			       player-loc get-location
			       player-angle get-float]
			      {:player user :vehicle vehicle :location player-loc :angle player-angle}))

(def get-talk (domonad state-m
		       [_ get-string
			talker get-person
			message get-string]
		       {:player talker :message message}))

(defn get-pickup-type [str-seq]
  (when (> (count str-seq) 0)
    (cond
      (= "Weapon" (first str-seq)) [:weapon (rest str-seq)]
      (= "Item" (first str-seq)) [:item (rest str-seq)])))

(def get-pickup (domonad state-m
			 [pickup-type get-pickup-type
			  acquierer get-person
			  item get-string]
			 {:player acquierer :type pickup-type :item item}))

(defn get-connection-type [str-seq]
  (when (> (count str-seq) 0)
    (cond
      (= "J" (first str-seq)) [:join (rest str-seq)]
      (= "Q" (first str-seq)) [:quit (rest str-seq)])))

(def get-connection (domonad state-m
			     [connection-type get-connection-type
			      connecter get-person]
			     {:player connecter :action connection-type}))

(def get-game-event (domonad state-m
			     [_ get-string
			      event-source get-person
			      event get-string
			      event-loc get-location
			      source-angle get-float
			      source-stance get-string]
			     {:player event-source :event event 
			      :location event-loc :angle source-angle :stance source-stance}))

(defn get-win-loss-type [str-seq]
  (when (> (count str-seq) 0)
    (cond
      (= "W" (first str-seq)) [:win (rest str-seq)]
      (= "L" (first str-seq)) [:loss (rest str-seq)])))

(def get-win-loss (domonad state-m
			   [win-loss-type get-win-loss-type
			    team get-team
			    players get-people]
			   {:team team :players players :type win-loss-type}))

(def get-game-start (domonad state-m
			     [_ get-string
			      game-type get-string
			      map-name get-string
			      round-time get-float
			      allies-team get-string
			      axis-team get-string]
			     {:game-type game-type :map-name map-name :round-time round-time
			      :allies-team allies-team :axis-team axis-team}))

(defn line-dispatch [str-seq]
  (let [first-entry (first str-seq)]
    (cond
      (= "Shell" first-entry) (first (get-shell-shock str-seq))
      (= "Spec" first-entry) (first (get-spectator str-seq))
      (= "Spawn" first-entry) (first (get-spawn str-seq))
      (or (= "K" first-entry) (= "D" first-entry)) (first (get-dk str-seq))
      (= "Use" first-entry) (first (get-use-vehicle str-seq))
      (or (= "say" first-entry) (= "sayteam" first-entry)) (first (get-talk str-seq))
      (or (= "Weapon" first-entry) (= "Use" first-entry)) (first (get-pickup str-seq))
      (or (= "J" first-entry) (= "Q" first-entry)) (first (get-connection str-seq))
      (or (= "W" first-entry) (= "L" first-entry)) (first (get-win-loss str-seq))
      (= "Game" first-entry) (first (get-game-start str-seq))
      (= "A" first-entry) (first (get-game-event str-seq)))))

(defn parse-time [time-string]
  (let [split-seq (re-split #":" time-string)]
    (+ (Float/parseFloat (first split-seq)) (/ (Float/parseFloat (second split-seq)) 60))))

(defn parse-line [line]
  (let [split-seq (re-split #" " (.trim line) 2)]
    {:time (parse-time (first split-seq)) :entry (line-dispatch (re-split #";" (second split-seq)))}))

(defn parse-connect-line [line]
  (let [split-seq (re-split #" " (.trim line) 2)]
    (when (= "Client" (first split-seq))
      (let [connect-seq (re-split #" " (second split-seq))]
	{:client-id (Integer/parseInt (first connect-seq))
	 :ip-address (last connect-seq)}))))

(defn split-log [file]
  (map parse-line (re-split #"[\r*\n]+" (slurp file))))

(defn player? [potential-struct]
  (and (contains? potential-struct :num)
       (contains? potential-struct :id)
       (contains? potential-struct :team)
       (contains? potential-struct :name)))

(defn hit-info? [potential-struct]
  (and (contains? potential-struct :weapon)
       (contains? potential-struct :damage)
       (contains? potential-struct :type)
       (contains? potential-struct :area)))

(defn damage-kill? [potential-struct]
  (and (contains? potential-struct :type)
       (contains? potential-struct :victim)
       (contains? potential-struct :attacker)
       (contains? potential-struct :hit-details)))
(defn kill? [dk-struct]
  (= (dk-struct :type) :kill))
(defn self-damage? [dk-struct]
  (= (dk-struct :victim) (dk-struct :attacker)))
(defn team-damage? [dk-struct]
  (= (:team (dk-struct :victim)) (:team (dk-struct :attacker))))

(defn talk? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :message)))

(defn pickup? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :type)
       (contains? potential-struct :item)))

(defn connection? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :action)))

(defn game-event? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :event)))

(defn win-loss? [potential-struct]
  (and (contains? potential-struct :team)
       (contains? potential-struct :players)
       (contains? potential-struct :type)))

(defn start-game? [potential-struct]
  (and (contains? potential-struct :game-type)
       (contains? potential-struct :map-name)
       (contains? potential-struct :round-time)))
