(ns org.stoop.codAnalytics
  (:use org.stoop.codParser org.stoop.codData
	clojure.contrib.seq-utils))

;General stuff

(defn get-log-type [log-seq predicate]
  (filter #(predicate (:entry %)) log-seq))

(defn select-player-from-seq [log-seq name-field name]
  (filter #(.equalsIgnoreCase name (get-in % [:entry name-field :name])) log-seq))

(defn select-pid-from-seq [log-seq id-field id]
  (filter #(= id (get-in % [:entry id-field :id])) log-seq))

(defn select-weapon-from-seq [dk-seq weapon-name]
  (filter #(.equalsIgnoreCase weapon-name (get-in % [:entry :hit-details :weapon])) dk-seq))

(defn select-weapon-type [dk-seq weapon-pred]
  (filter #(weapon-pred (get-in % [:entry :hit-details :weapon])) dk-seq))

(defn select-hit-area [dk-seq area-name]
  (filter #(.equalsIgnoreCase area-name (get-in % [:entry :hit-details :area])) dk-seq))

(defn select-damage-type [dk-seq type-name]
  (filter #(.equalsIgnoreCase type-name (get-in % [:entry :hit-details :type])) dk-seq))

;Get unique stuff from sequences

(defn get-unique-from-seq [log-seq nested-keys]
  (distinct (doall (map #(get-in % nested-keys) log-seq))))

(defn get-unique-names-from-seq [log-seq name-field]
  (remove nil? (get-unique-from-seq log-seq [:entry name-field :name])))

(defn get-unique-ids-from-seq [log-seq id-field]
  (remove nil? (get-unique-from-seq log-seq [:entry id-field :id])))

(defn get-all-ids [dk-seq]
  (let [attack-ids (get-unique-ids-from-seq dk-seq :attacker)
	victim-ids (get-unique-ids-from-seq dk-seq :victim)]
    (distinct (concat attack-ids victim-ids))))

(defn get-unique-weapons-from-seq [dk-seq]
  (get-unique-from-seq dk-seq [:entry :hit-details :weapon]))

;One of something calculations

;Play time
(defn get-time-played [log-seq player-id]
  (let [start-games (get-log-type log-seq start-game?)
	dk-seq (get-log-type log-seq damage-kill?)
	k-seq (get-log-type dk-seq kill?)
	player-d-seq (select-pid-from-seq k-seq :victim player-id)
	spawn-seq (get-log-type log-seq spawn?)
	player-spawn-seq (select-pid-from-seq spawn-seq :spawn player-id)
	master-seq (sort-by :time (concat start-games player-d-seq player-spawn-seq))
	paired-seq (partition 2 1 master-seq)
	valid-pairs (filter #(and (spawn? (:entry (first %)))
				  (or (kill? (:entry (second %)))
				      (start-game? (:entry (second %))))) paired-seq)
	play-times (map #(- (:time (second %)) (:time (first %))) valid-pairs)]
    (reduce + play-times)))

;Best weapons
(defn get-best-weapon [dk-seq player-id]
  (let [k-good-recs (get-log-type dk-seq clean-kill?)
	player-ks (select-pid-from-seq k-good-recs :attacker player-id)
	weapons (get-unique-weapons-from-seq player-ks)]
    (:weapon (first (reverse (sort-by :value (for [weapon weapons]
					       {:weapon weapon 
						:value (count (select-weapon-from-seq player-ks weapon))})))))))

;Streaks
(defn get-max-kill-streak [dk-seq player-id]
  (let [kills (get-log-type dk-seq #(or (clean-kill? %) (and (kill? %)
							     (= player-id (get-in % [:entry :victim :id])))))
	player-ks (select-pid-from-seq kills :attacker player-id)
	player-name (get-in (last player-ks) [:entry :attacker :name])
	player-ds (select-pid-from-seq kills :victim player-id)
	player-ks-ds (sort-by :time (concat player-ks player-ds))
	player-streaks (partition-by #(= player-id (get-in % [:entry :victim :id])) player-ks-ds)
	kill-streaks (filter #(= player-id (get-in (first %) [:entry :attacker :id])) player-streaks)
	streak-lengths (map count kill-streaks)]
    (when (> (count streak-lengths) 0)
      {:name player-name :value (apply max streak-lengths)})))

(defn get-max-death-streak [dk-seq player-id]
  (let [kills (get-log-type dk-seq #(or (clean-kill? %) (and (kill? %)
							     (= player-id (get-in % [:entry :victim :id])))))
	player-ks (select-pid-from-seq kills :attacker player-id)
	player-ds (select-pid-from-seq kills :victim player-id)
	player-name (get-in (last player-ds) [:entry :victim :name])
	player-ks-ds (sort-by :time (concat player-ks player-ds))
	player-streaks (partition-by #(= player-id (get-in % [:entry :victim :id])) player-ks-ds)
	death-streaks (filter #(= player-id (get-in (first %) [:entry :victim :id])) player-streaks)
	streak-lengths (map count death-streaks)]
    (when (> (count streak-lengths) 0)
      {:name player-name :value (apply max streak-lengths)})))

;Get totals of stuff and create rankings

;Generic builders
(defn sum-over [log-seq nested-keys]
  (reduce + (doall (map #(get-in % nested-keys) log-seq))))

(defn create-ranking [value-function log-seq player-seq]
  (reverse (sort-by :value (doall (map #(value-function log-seq %) player-seq)))))

;Specific calculations and rankings
(defn get-total-damage-dealt [dk-seq player-id]
  (let [dk-good-recs (get-log-type dk-seq clean-damage?)
	player-dks (select-pid-from-seq dk-good-recs :attacker player-id)
	player-name (get-in (last player-dks) [:entry :attacker :name])]
    {:name player-name :value (sum-over player-dks [:entry :hit-details :damage])}))

(defn get-total-damage-received [dk-seq player-id]
  (let [dk-good-recs (get-log-type dk-seq clean-damage?)
	player-dks (select-pid-from-seq dk-good-recs :victim player-id)
	player-name (get-in (last player-dks) [:entry :victim :name])]
    {:name player-name :value (sum-over player-dks [:entry :hit-details :damage])}))

(defn get-total-team-damage-dealt [dk-seq player-id]
  (let [dk-player-recs (get-log-type dk-seq non-npc?)
	dk-team-recs (get-log-type dk-player-recs team-damage?)
	player-td (select-pid-from-seq dk-team-recs :attacker player-id)
	player-name (get-in (last player-td) [:entry :attacker :name])]
    {:name player-name :value (sum-over player-td [:entry :hit-details :damage])}))

(defn get-total-team-damage-received [dk-seq player-id]
  (let [dk-player-recs (get-log-type dk-seq #(and (non-npc? %) (not (self-damage? %))))
	dk-team-recs (get-log-type dk-player-recs team-damage?)
	player-td (select-pid-from-seq dk-team-recs :victim player-id)
	player-name (get-in (last player-td) [:entry :victim :name])]
    {:name player-name :value (sum-over player-td [:entry :hit-details :damage])}))

(defn get-num-kills [dk-seq player-id]
  (let [k-good-recs (get-log-type dk-seq clean-kill?)
	player-ks (select-pid-from-seq k-good-recs :attacker player-id)
	player-name (get-in (last player-ks) [:entry :attacker :name])]
    {:name player-name :value (count player-ks)}))

(defn get-num-team-kills [dk-seq player-id]
  (let [dk-player-recs (get-log-type dk-seq non-npc?)
	dk-team-recs (get-log-type dk-player-recs team-damage?)
	tk-recs (get-log-type dk-team-recs kill?)
	player-tks (select-pid-from-seq tk-recs :attacker player-id)
	player-name (get-in (last player-tks) [:entry :attacker :name])]
    {:name player-name :value (count player-tks)}))

(defn get-num-deaths [dk-seq player-id]
  (let [k-recs (get-log-type dk-seq kill?)
	player-ds (select-pid-from-seq k-recs :victim player-id)
	player-name (get-in (last player-ds) [:entry :victim :name])]
    {:name player-name :value (count player-ds)}))

(defn get-num-suicides [dk-seq player-id]
  (let [sui-recs (get-log-type dk-seq suicide?)
	player-suis (select-pid-from-seq sui-recs :attacker player-id)
	player-name (get-in (last player-suis) [:entry :attacker :name])]
    {:name player-name :value (count player-suis)}))

(defn get-total-self-damage [dk-seq player-id]
  (let [self-recs (get-log-type dk-seq self-damage?)
	player-recs (select-pid-from-seq self-recs :attacker player-id)
	player-name (get-in (last player-recs) [:entry :attacker :name])]
    {:name player-name :value (sum-over player-recs [:entry :hit-details :damage])}))

(defn get-total-fall-damage [dk-seq player-id]
  (let [fall-recs (select-damage-type dk-seq "MOD_FALLING")
	player-falls (select-pid-from-seq fall-recs :victim player-id)
	player-name (get-in (last player-falls) [:entry :victim :name])]
    {:name player-name :value (sum-over player-falls [:entry :hit-details :damage])}))

(defn get-total-damage-to-world [dk-seq player-id]
  (let [world-recs (get-log-type dk-seq hurt-world?)
	player-dam (select-pid-from-seq world-recs :attacker player-id)
	player-name (get-in (last player-dam) [:entry :attacker :name])]
    {:name player-name :value (sum-over player-dam [:entry :hit-details :damage])}))

(defn get-total-damage-from-world [dk-seq player-id]
  (let [world-recs (get-log-type dk-seq world-damage?)
	player-dam (select-pid-from-seq world-recs :victim player-id)
	player-name (get-in (last player-dam) [:entry :victim :name])]
    {:name player-name :value (sum-over player-dam [:entry :hit-details :damage])}))

(defn get-total-self-fire-damage [dk-seq player-id]
  (let [fire-recs (select-damage-type dk-seq "MOD_FLAME")]
    (get-total-self-damage fire-recs player-id)))

(defn get-num-talks [chat-recs player-id]
  (let [player-talks (select-pid-from-seq chat-recs :player player-id)
	player-name (get-in (last player-talks) [:entry :player :name])]
    {:name player-name :value (count player-talks)}))

(defn get-num-item-pickups [item-recs player-id]
  (let [player-wep-picks (select-pid-from-seq item-recs :player player-id)
	player-name (get-in (last player-wep-picks) [:entry :player :name])]
    {:name player-name :value (count player-wep-picks)}))

(defn get-shock-duration [shock-recs player-id]
  (let [player-shocks (select-pid-from-seq shock-recs :shock player-id)
	player-name (get-in (last player-shocks) [:entry :shock :name])]
    {:name player-name :value (sum-over player-shocks [:entry :shock-info :damage])}))

;Wins and losses for various game types

(defn has-player? [player-seq player-id]
  (> (count (filter #(= player-id (:id %)) player-seq)) 0))

(defn get-player-in-seq [player-seq player-id]
  (last (filter #(= player-id (:id %)) player-seq)))

(defn get-wins [win-loss-seq player-id]
  (let [wins (filter #(= :win (get-in % [:entry :type])) win-loss-seq)
	player-wins (filter #(has-player? (get-in % [:entry :players]) player-id) wins)
	player-name (:name (get-player-in-seq (get-in (last player-wins) [:entry :players]) player-id))]
    {:name player-name :value (count player-wins)}))

(defn get-losses [win-loss-seq player-id]
  (let [losses (filter #(= :loss (get-in % [:entry :type])) win-loss-seq)
	player-losses (filter #(has-player? (get-in % [:entry :players]) player-id) losses)
	player-name (:name (get-player-in-seq (get-in (last player-losses) [:entry :players]) player-id))]
    {:name player-name :value (count player-losses)}))

(defn partition-game-win-loss [log-seq]
  (let [game-win-loss (get-log-type log-seq #(or (start-game? %) (win-loss? %)))
	partitioned-list (partition 3 1 game-win-loss)
	valid-ones (filter #(and (start-game? (:entry (first %))) 
				 (win-loss? (:entry (second %))))
			   partitioned-list)]
    valid-ones))

(defn filter-game-type [game-win-loss-triple-seq game-type]
  (let [filtered-list (filter #(= game-type (:game-type (:entry (first %)))) game-win-loss-triple-seq)]
    (flatten (for [triple filtered-list]
	       (for [item (rest triple)]
		 item)))))

(defn get-number-wins [log-seq game-type player-id]
  (let [partitioned (partition-game-win-loss log-seq)
	filtered (filter-game-type partitioned game-type)]
    (get-wins filtered player-id)))

(defn get-number-losses [log-seq game-type player-id]
  (let [partitioned (partition-game-win-loss log-seq)
	filtered (filter-game-type partitioned game-type)]
    (get-losses filtered player-id)))

(defmacro create-game-type-calculators [game-type postfix]
  `(do 
     (defn ~(symbol (str "get-number-" game-type postfix)) [log-seq# player-id#] 
       (~(symbol (str "get-number" postfix)) log-seq# ~game-type player-id#))
     (defn ~(symbol (str "rank-num-" game-type postfix)) [log-seq#]
       (let [join-seq# (get-log-type log-seq# join?)
	     player-seq# (get-unique-ids-from-seq join-seq# :player)]
	 (create-ranking ~(symbol (str "get-number-" game-type postfix)) log-seq# player-seq#)))))

(create-game-type-calculators "tdm" "-wins") (create-game-type-calculators "tdm" "-losses")
(create-game-type-calculators "ctf" "-wins") (create-game-type-calculators "ctf" "-losses")
(create-game-type-calculators "dom" "-wins") (create-game-type-calculators "dom" "-losses")
(create-game-type-calculators "ftf" "-wins") (create-game-type-calculators "ftf" "-losses")
(create-game-type-calculators "sftf" "-wins") (create-game-type-calculators "sftf" "-losses")

;Calculate overall rankings of things

(defn rank-num-kills [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-num-kills dk-seq player-seq)))

(defn rank-num-team-kills [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-num-team-kills dk-seq player-seq)))

(defn rank-total-dam-dealt [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-total-damage-dealt dk-seq player-seq)))

(defn rank-total-dam-received [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-total-damage-received dk-seq player-seq)))

(defn rank-total-team-dam-received [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-total-team-damage-received dk-seq player-seq)))

(defn rank-num-deaths [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-num-deaths dk-seq player-seq)))

(defn rank-num-suicides [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-num-suicides dk-seq player-seq)))

(defn rank-num-talks [log-seq]
  (let [talk-seq (get-log-type log-seq talk?)
	player-seq (get-unique-ids-from-seq talk-seq :player)]
    (create-ranking get-num-talks talk-seq player-seq)))

(defn rank-num-weapon-pickups [log-seq]
  (let [weapon-seq (get-log-type log-seq weapon-pickup?)
	player-seq (get-unique-ids-from-seq weapon-seq :player)]
    (create-ranking get-num-item-pickups weapon-seq player-seq)))

(defn rank-num-item-pickups [log-seq]
  (let [item-seq (get-log-type log-seq item-pickup?)
	player-seq (get-unique-ids-from-seq item-seq :player)]
    (create-ranking get-num-item-pickups item-seq player-seq)))

(defn rank-shock-duration [log-seq]
  (let [shock-seq (get-log-type log-seq shell-shock?)
	player-seq (get-unique-ids-from-seq shock-seq :shock)]
    (create-ranking get-shock-duration shock-seq player-seq)))

(defn rank-kills-plus-deaths [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (distinct (concat (get-unique-ids-from-seq dk-seq :attacker)
				     (get-unique-ids-from-seq dk-seq :victim)))]
    (create-ranking #(let [kills (get-num-kills %1 %2)
			   deaths (get-num-deaths %1 %2)]
		       {:name (:name kills) :value (+ (:value kills) (:value deaths))})
		    dk-seq player-seq)))

(defn rank-total-fall-damage [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-total-fall-damage dk-seq player-seq)))

(defn rank-total-self-damage [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-total-self-damage dk-seq player-seq)))

(defn rank-total-world-damage [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-total-damage-to-world dk-seq player-seq)))

(defn rank-total-damage-from-world [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-total-damage-from-world dk-seq player-seq)))

(defn rank-self-fire-damage [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-total-self-fire-damage dk-seq player-seq)))

(defn rank-kill-streaks [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-max-kill-streak dk-seq player-seq)))

(defn rank-death-streaks [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-max-death-streak dk-seq player-seq)))

(defn create-weapon-ranking [value-function weapon-predicate log-seq player-seq]
  (reverse (sort-by :value (doall (map #(value-function (select-weapon-type log-seq weapon-predicate) %) player-seq)))))

(defn rank-weapon-damage [log-seq weapon-predicate]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-weapon-ranking get-total-damage-dealt weapon-predicate dk-seq player-seq)))

(defn rank-weapon-damage-received [log-seq weapon-predicate]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-weapon-ranking get-total-damage-received weapon-predicate dk-seq player-seq)))

(defn rank-weapon-kills [log-seq weapon-predicate]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-weapon-ranking get-num-kills weapon-predicate dk-seq player-seq)))

(defn rank-weapon-deaths [log-seq weapon-predicate]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-weapon-ranking get-num-deaths weapon-predicate dk-seq player-seq)))

(defn rank-artillery-damage [log-seq]
  (rank-weapon-damage log-seq artillery?))

(defn rank-bazooka-damage [log-seq]
  (rank-weapon-damage log-seq bazooka?))

(defn rank-russian-wep-kills [log-seq]
  (rank-weapon-kills log-seq russian?))

(defn rank-flamethrower-damage [log-seq]
  (rank-weapon-damage log-seq flame-thrower?))

(defn rank-flamethrower-dam-received [log-seq]
  (rank-weapon-damage-received log-seq flame-thrower?))

(defn rank-fubar-damage [log-seq]
  (rank-weapon-damage log-seq fubar?))

(defn rank-grenade-damage [log-seq]
  (rank-weapon-damage log-seq grenade?))

(defn rank-heavy-mg-kills [log-seq]
  (rank-weapon-kills log-seq heavy-mg?))

(defn rank-jeep-gun-kills [log-seq]
  (rank-weapon-kills log-seq jeep?))

(defn rank-light-mg-kills [log-seq]
  (rank-weapon-kills log-seq light-mg?))

(defn rank-british-wep-kills [log-seq]
  (rank-weapon-kills log-seq british?))

(defn rank-german-wep-kills [log-seq]
  (rank-weapon-kills log-seq german?))

(defn rank-pistol-kills [log-seq]
  (rank-weapon-kills log-seq pistol?))

(defn rank-rifle-kills [log-seq]
  (rank-weapon-kills log-seq rifle?))

(defn rank-tank-kills [log-seq]
  (rank-weapon-kills log-seq tank?))

(defn rank-american-wep-kills [log-seq]
  (rank-weapon-kills log-seq american?))

(defn pad-number [padee]
  (if (> 10 padee)
    (str "0" padee)
    (str padee)))

(defn convert-to-hms [time-in-minutes]
  (let [hours (int (/ time-in-minutes 60))
	minutes (int (mod time-in-minutes 60))
	seconds (int (mod (* 60 time-in-minutes) 60))]
    (str (pad-number hours) ":" (pad-number minutes) ":" (pad-number seconds))))

(defn get-best-enemy [dk-seq player-id]
  (let [k-good-recs (get-log-type dk-seq clean-kill?)
	player-ds (select-pid-from-seq k-good-recs :victim player-id)
	attacker-ids (get-unique-ids-from-seq player-ds :attacker)]
    (:name (first (reverse (sort-by :value (for [attacker-id attacker-ids]
					     (get-num-kills player-ds attacker-id))))))))

(defn get-leaderboard-stats [player-id log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	kill-results (get-num-kills dk-seq player-id)
	death-results (get-num-deaths dk-seq player-id)
	suicide-results (get-num-suicides dk-seq player-id)
	inflicted-results (get-total-damage-dealt dk-seq player-id)
	received-results (get-total-damage-received dk-seq player-id)]
    (list (:name kill-results)
	  (:value kill-results)
	  (:value death-results)
	  (:value suicide-results)
	  (convert-to-hms (get-time-played log-seq player-id))
	  (:value inflicted-results)
	  (:value received-results)
	  (get-best-weapon dk-seq player-id)
	  (get-best-enemy dk-seq player-id))))

(defn get-all-leaderboard-stats [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-ids (get-all-ids dk-seq)]
    (filter #(not (nil? %))
	    (for [player-id player-ids]
	      (let [leader-stats (get-leaderboard-stats player-id log-seq)]
		(when (not (nil? (first leader-stats)))
		  leader-stats))))))