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
    (constant-semantics (lit-conc-seq "allies" nb-char-lit) :allies)))

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

(defstruct damage-kill-struct :type :victim :attacker :hit-details)
(defn damage-kill? [potential-struct]
  (and (contains? potential-struct :type)
       (contains? potential-struct :victim)
       (contains? potential-struct :attacker)
       (contains? potential-struct :hit-details)))

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
	      hit-details hit-info]
      (struct damage-kill-struct type victim attacker hit-details))
    (complex [type pain-type
	      _ semi-colon-lit
	      victim player
	      _ semi-colon-lit
	      _ (lit-conc-seq ";-1;world;;")
	      hit-details hit-info]
      (struct damage-kill-struct type victim :world hit-details))))

(defstruct talk-struct :player :message)
(defn talk? [potential-struct]
  (and (contains? potential-struct :player)
       (contains? potential-struct :message)))

(def talk-id
  (alt (lit-conc-seq "say" nb-char-lit) (lit-conc-seq "sayteam" nb-char-lit)))

(def talk-action
  (complex [talk-type talk-id
	    _ semi-colon-lit
	    talker player
	    _ semi-colon-lit
	    message get-remainder]
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

(def player-semi
  (complex [player-name player
	    _ (opt semi-colon-lit)]
    player-name))

(def win-loss-event
  (alt
    (complex [_ (nb-char-lit \W)
	      _ semi-colon-lit
	      team-name team
	      _ semi-colon-lit
	      players (rep* player-semi)]
      (struct win-loss-struct team-name players :win))
    (complex [_ (nb-char-lit \L)
	      _ semi-colon-lit
	      team-name team
	      _ semi-colon-lit
	      players (rep* player-semi)]
      (struct win-loss-struct team-name players :loss))))

(defstruct server-action-struct :command :arguments)
(defn server-action? [potential-struct]
  (and (contains? potential-struct :command)
       (contains? potential-struct :arguments)))

(def server-action
  (complex [command non-colon-string
	    _ colon-lit
	    _ (opt ws)
	    arguments get-remainder]
    (struct server-action-struct command (apply-str arguments))))

(def section-splitter
  (rep* (nb-char-lit \-)))

(def player-action
  (alt damage-kill talk-action pickup join-quit game-event win-loss-event))

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
      nil)))
	      