(ns org.stoop.codParser
  (:use name.choi.joshua.fnparse org.stoop.parser))

(defstruct time-struct :minute :second)

(def time-stamp
  (complex [minute number-lit
	    _ colon-lit
	    second number-lit]
    (struct time-struct minute second)))

(def team
  (alt
    (constant-semantics (lit-conc-seq "axis" nb-char-lit) :axis)
    (constant-semantics (lit-conc-seq "allies" nb-char-lit) :allies)
    (constant-semantics (lit-conc-seq "all" nb-char-lit) :all)))

(defstruct player-struct :num :id :team :name)
(defn player? [potential-struct]
  (and (contains? potential-struct :num)
       (contains? potential-struct :id)
       (contains? potential-struct :team)
       (contains? potential-struct :name)))

(def player
  (alt
    (complex [player-num number-lit
	      _ semi-colon-lit
	      player-id number-lit
	      _ semi-colon-lit
	      team-name team
	      _ semi-colon-lit
	      player-name identifier]
	     (struct player-struct player-num player-id team-name player-name))
    (complex [player-num number-lit
	      _ semi-colon-lit
	      player-id number-lit
	      _ semi-colon-lit
	      player-name identifier]
	     (struct player-struct player-num player-id :none player-name))
    (complex [player-num number-lit
	      _ semi-colon-lit
	      player-name identifier]
	     (struct player-struct player-num 0 :none player-name))))

(def spectator
  (complex [_ (lit-conc-seq "Spec" nb-char-lit)
	    _ semi-colon-lit
	    spectator-player player]
    {:spectator spectator-player}))

(def rank
  (complex [_ (lit-conc-seq "Rank" nb-char-lit)
	    _ semi-colon-lit
	    rank-player player
	    _ semi-colon-lit
	    new-rank number-lit]
    {:player rank-player :rank new-rank}))

(defstruct hit-info-struct :weapon :damage :type :area)
(defn hit-info? [potential-struct]
  (and (contains? potential-struct :weapon)
       (contains? potential-struct :damage)
       (contains? potential-struct :type)
       (contains? potential-struct :area)))

(def hit-info
  (complex [weapon identifier
	    _ semi-colon-lit
	    damage number-lit
	    _ semi-colon-lit
	    type identifier
	    _ semi-colon-lit
	    area identifier]
    (struct hit-info-struct weapon damage type area)))

(def shell-shock
  (complex [_ (lit-conc-seq "Shock" nb-char-lit)
	    _ semi-colon-lit
	    shocked-player player
	    _ semi-colon-lit
	    shock-info hit-info]
    {:shock shocked-player, :shock-info shock-info}))

(def location
  (complex [x number-lit
	    _ comma-lit
	    y number-lit
	    _ comma-lit
	    z number-lit]
  {:z z :y y :x x}))

(def spawn
  (complex [_ (lit-conc-seq "Spawn" nb-char-lit)
	    _ semi-colon-lit
	    spawned-player player
	    _ semi-colon-lit
	    spawn-weapon identifier
	    _ semi-colon-lit
	    spawn-location location]
    {:spawn spawned-player, :weapon spawn-weapon, :location location}))

(defstruct damage-kill-struct :type :victim :attacker :hit-details :victim-loc :attacker-loc :victim-angle :attacker-angle :victim-stance :attacker-stance)

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

(def pain-type
  (alt
    (constant-semantics (nb-char-lit \D) :damage)
    (constant-semantics (nb-char-lit \K) :kill)))

(def damage-kill
  (alt
    (complex [type pain-type
	      _ semi-colon-lit
	      victim player
	      _ semi-colon-lit
	      attacker player
	      _ semi-colon-lit
	      hit-details hit-info
	      _ semi-colon-lit
	      victim-loc location
	      _ semi-colon-lit
	      attacker-loc location
	      _ semi-colon-lit
	      victim-angle number-lit
	      _ semi-colon-lit
	      attacker-angle number-lit
	      _ semi-colon-lit
	      victim-stance identifier
	      _ semi-colon-lit
	      attacker-stance identifier]
      (struct damage-kill-struct type victim attacker hit-details victim-loc attacker-loc victim-angle attacker-angle victim-stance attacker-stance))
    (complex [type pain-type
	      _ semi-colon-lit
	      victim player
	      _ semi-colon-lit
	      attacker player
	      _ semi-colon-lit
	      hit-details hit-info
	      _ semi-colon-lit
	      victim-loc location
	      _ semi-colon-lit
	      attacker-loc location]
      (struct damage-kill-struct type victim attacker hit-details victim-loc attacker-loc))
    (complex [type pain-type
	      _ semi-colon-lit
	      victim player
	      _ semi-colon-lit
	      attacker player
	      _ semi-colon-lit
	      hit-details hit-info]
      (struct damage-kill-struct type victim attacker hit-details))
    (complex [type pain-type
	      _ semi-colon-lit
	      victim player
	      _ semi-colon-lit
	      _ (lit-conc-seq ";-1;world;;" nb-char-lit)
	      hit-details hit-info]
      (struct damage-kill-struct type victim (struct player-struct 0 -1 "world" "world") hit-details))))

(def vehicle
  (complex [vehicle-num number-lit
	    _ semi-colon-lit
	    vehicle-team team
	    _ semi-colon-lit
	    vehicle-type identifier
	    _ semi-colon-lit
	    vehicle-seat number-lit]
    {:vehicle vehicle-type :id vehicle-num :team team :seat vehicle-seat}))

(def use-vehicle
  (complex [_ (lit-conc-seq "Use" nb-char-lit)
	    _ semi-colon-lit
	    user-player player
	    _ semi-colon-lit
	    used-entity vehicle
	    _ semi-colon-lit
	    player-loc location
	    _ semi-colon-lit
	    player-angle number-lit]
    {:player user-player :vehicle used-entity :location player-loc :angle player-angle}))

(defstruct talk-struct :player :message)
(defn talk? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :message)))

(def talk-id
  (alt
    (constant-semantics (lit-conc-seq "sayteam" nb-char-lit) :sayteam)
    (constant-semantics (lit-conc-seq "say" nb-char-lit) :say)))

(def talk-action
  (complex [talk-type talk-id
	    _ semi-colon-lit
	    talker player
	    _ semi-colon-lit
	    message rest-of-line]
    (struct talk-struct talker (apply-str message))))

(defstruct pickup-struct :player :type :item)
(defn pickup? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :type)
       (contains? potential-struct :item)))

(def pickup-type
  (alt
    (constant-semantics (lit-conc-seq "Weapon" nb-char-lit) :weapon)
    (constant-semantics (lit-conc-seq "Item" nb-char-lit) :item)))

(def pickup
  (complex [type pickup-type
	    _ semi-colon-lit
	    acquierer player
	    _ semi-colon-lit
	    item identifier]
    (struct pickup-struct acquierer type item)))

(defstruct connection-struct :player :action)
(defn connection? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :action)))

(def join-quit
  (alt
    (complex [_ (nb-char-lit \J)
	      _ semi-colon-lit
	      joiner player]
      (struct connection-struct joiner :join))
    (complex [_ (nb-char-lit \Q)
	      _ semi-colon-lit
	      quitter player]
      (struct connection-struct quitter :quit))))

(defstruct game-event-struct :player :event)
(defn game-event? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :event)))

(def game-event
  (complex [_ (nb-char-lit \A)
	    _ semi-colon-lit
	    event-source player
	    _ semi-colon-lit
	    event rest-of-line]
    (struct game-event-struct event-source event)))

(defstruct win-loss-struct :team :players :type)
(defn win-loss? [potential-struct]
  (and (contains? potential-struct :team)
       (contains? potential-struct :players)
       (contains? potential-struct :type)))

(def semi-player
  (complex [_ semi-colon-lit
	    player-name player]
    player-name))

(def win-loss-event
  (alt
    (complex [_ (nb-char-lit \W)
	      _ semi-colon-lit
	      team-name team
	      players (rep* semi-player)]
      (struct win-loss-struct team-name players :win))
    (complex [_ (nb-char-lit \L)
	      _ semi-colon-lit
	      team-name team
	      players (rep* semi-player)]
      (struct win-loss-struct team-name players :loss))))

(defstruct server-action-struct :command :arguments)
(defn server-action? [potential-struct]
  (and (contains? potential-struct :command)
       (contains? potential-struct :arguments)))

(defstruct server-argument-struct :name :value)
(defn server-argument? [potential-struct]
  (and (contains? potential-struct :name)
       (contains? potential-struct :value)))

(def server-argument
 (complex [_ (nb-char-lit \\)
	   argument-name non-backslash-string
	   _ (nb-char-lit \\)
	   argument-value non-backslash-string]
   (struct server-argument-struct argument-name argument-value)))

(def start-game
  (complex [_ (lit-conc-seq "Game")
	    _ semi-colon-lit
	    game-type identifier
	    _ semi-colon-lit
	    map-name identifier
	    _ semi-colon-lit
	    round-time number-lit]
    {:command :start, :arguments nil, :game-type game-type, :map-name map-name, :round-time round-time}))

(def server-command
  (alt
    (lit-conc-seq "InitGame" nb-char-lit)
    (lit-conc-seq "ExitLevel" nb-char-lit)
    (lit-conc-seq "RestartGame" nb-char-lit)
    (lit-conc-seq "ShutdownGame" nb-char-lit)))

(def server-action
  (alt
    (complex [command server-command
	      _ colon-lit
	      _ ws
	      arguments (rep+ server-argument)]
      (struct server-action-struct command arguments))
    (complex [command server-command
	      _ colon-lit
	      _ (opt ws)
	      argument rest-of-line]
      (struct server-action-struct command argument))
    (complex [command server-command
	      _ colon-lit
	      _ (opt ws)]
      (struct server-action-struct command :none))
    start-game))

(def section-splitter
  (factor= 60 (nb-char-lit \-)))

(def player-action
  (alt damage-kill talk-action pickup join-quit game-event win-loss-event spectator shell-shock spawn rank use-vehicle))

(defstruct log-entry-struct :time :entry)

(def log-line
  (alt
    (complex [_ (opt ws)
	      time time-stamp
	      _ ws
	      log-entry player-action]
      (struct log-entry-struct time log-entry))
    (complex [_ (opt ws)
	      time time-stamp
	      _ ws
	      log-entry server-action]
      (struct log-entry-struct time log-entry))
    (complex [_ (opt ws)
	      time time-stamp
	      _ ws
	      log-entry section-splitter]
      (struct log-entry-struct time log-entry))))

(def log-file
  (complex [entries (rep* (invisi-conc log-line (rep+ line-break)))
	    last-entry (invisi-conc log-line (opt line-break))]
    (conj entries last-entry)))

;(defn parse-log [file]
;  (parse (slurp file) log-file))

(defn parse-log [file]
  (with-open [fr (java.io.FileReader. file)
              br (java.io.BufferedReader. fr)]
    (vec (doall (map #(parse % log-line) (line-seq br))))))