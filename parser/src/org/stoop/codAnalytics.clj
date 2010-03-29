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

(defn select-hit-area [dk-seq area-pred]
  (filter #(area-pred (get-in % [:entry :hit-details :area])) dk-seq))

(defn select-damage-type [dk-seq type-name]
  (filter #(.equalsIgnoreCase type-name (get-in % [:entry :hit-details :type])) dk-seq))

(defn select-event-type [event-seq event-name]
  (filter #(.equalsIgnoreCase event-name (get-in % [:entry :event])) event-seq))

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

(defn list-names [dk-seq player-id]
  (let [player-recs (select-pid-from-seq dk-seq :victim player-id)]
    (get-unique-names-from-seq player-recs :victim)))

(defn list-all-names-ids [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-ids (get-all-ids dk-seq)]
    (for [player-id player-ids]
      {:id player-id :names (list-names dk-seq player-id)})))

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

(defn get-num-water-deaths [dk-seq player-id]
  (let [kill-recs (get-log-type dk-seq kill?)
	player-ds (select-pid-from-seq kill-recs :victim player-id)
	water-recs (select-damage-type player-ds "MOD_TRIGGER_HURT")
	player-name (get-in (last water-recs) [:entry :victim :name])]
    {:name player-name :value (count water-recs)}))

(defn get-num-melee-kills [dk-seq player-id]
  (let [kill-recs (get-log-type dk-seq clean-kill?)
	player-ks (select-pid-from-seq kill-recs :attacker player-id)
	melee-recs (select-damage-type player-ks "MOD_MELEE")]
    (count melee-recs)))

(defn get-num-artillery-kills [dk-seq player-id]
  (let [kill-recs (get-log-type dk-seq clean-kill?)
	player-ks (select-pid-from-seq kill-recs :attacker player-id)
	arti-recs (select-weapon-type player-ks artillery?)]
    (count arti-recs)))

(defn get-num-lame-kills [dk-seq player-id]
  (let [player-recs (select-pid-from-seq dk-seq :attacker player-id)
	player-name (get-in (last player-recs) [:entry :attacker :name])]
    {:name player-name
     :value (+ (get-num-melee-kills dk-seq player-id) (get-num-artillery-kills dk-seq player-id))}))

(defn get-total-jeep-crush-damage [dk-seq player-id]
  (let [clean-recs (get-log-type dk-seq clean-damage?)
	jeep-crush-recs (select-damage-type clean-recs "MOD_CRUSH_JEEP")
	player-crushes (select-pid-from-seq jeep-crush-recs :attacker player-id)
	player-name (get-in (last player-crushes) [:entry :attacker :name])]
    {:name player-name :value (sum-over player-crushes [:entry :hit-details :damage])}))

(defn get-total-tank-crush-damage [dk-seq player-id]
  (let [clean-recs (get-log-type dk-seq clean-damage?)
	tank-crush-recs (select-damage-type clean-recs "MOD_CRUSH_TANK")
	player-crushes (select-pid-from-seq tank-crush-recs :attacker player-id)
	player-name (get-in (last player-crushes) [:entry :attacker :name])]
    {:name player-name :value (sum-over player-crushes [:entry :hit-details :damage])}))

;Non-DK computations

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

(defn get-num-ctf-takes [event-recs player-id]
  (let [ctf-takes (select-event-type event-recs "ctf_take")
	player-takes (select-pid-from-seq ctf-takes :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ctf-captures [event-recs player-id]
  (let [ctf-captures (select-event-type event-recs "ctf_captured")
	player-takes (select-pid-from-seq ctf-captures :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ctf-returns [event-recs player-id]
  (let [ctf-returns (select-event-type event-recs "ctf_returned")
	player-takes (select-pid-from-seq ctf-returns :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ctf-pickups [event-recs player-id]
  (let [ctf-pickups (select-event-type event-recs "ctf_pickup")
	player-takes (select-pid-from-seq ctf-pickups :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-dom-takes [event-recs player-id]
  (let [dom-takes (select-event-type event-recs "dom_take")
	player-takes (select-pid-from-seq dom-takes :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-dom-captures [event-recs player-id]
  (let [dom-captures (select-event-type event-recs "dom_captured")
	player-takes (select-pid-from-seq dom-captures :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-dom-defends [event-recs player-id]
  (let [dom-defends (select-event-type event-recs "dom_defended")
	player-takes (select-pid-from-seq dom-defends :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-dom-fails [event-recs player-id]
  (let [dom-fails (select-event-type event-recs "dom_fail")
	player-takes (select-pid-from-seq dom-fails :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-dom-assists [event-recs player-id]
  (let [dom-assists (select-event-type event-recs "dom_assist")
	player-takes (select-pid-from-seq dom-assists :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ftf-steals [event-recs player-id]
  (let [ftf-steals (select-event-type event-recs "ftf_stole")
	player-takes (select-pid-from-seq ftf-steals :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ftf-scores [event-recs player-id]
  (let [ftf-scores (select-event-type event-recs "ftf_scored")
	player-takes (select-pid-from-seq ftf-scores :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ftf-defends [event-recs player-id]
  (let [ftf-defends (select-event-type event-recs "ftf_defended")
	player-takes (select-pid-from-seq ftf-defends :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ftf-fails [event-recs player-id]
  (let [ftf-fails (select-event-type event-recs "ftf_fail")
	player-takes (select-pid-from-seq ftf-fails :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-ftf-assists [event-recs player-id]
  (let [ftf-assists (select-event-type event-recs "ftf_assist")
	player-takes (select-pid-from-seq ftf-assists :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-sftf-steals [event-recs player-id]
  (let [sftf-steals (select-event-type event-recs "sftf_stole")
	player-takes (select-pid-from-seq sftf-steals :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-sftf-scores [event-recs player-id]
  (let [sftf-scores (select-event-type event-recs "sftf_scored")
	player-takes (select-pid-from-seq sftf-scores :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-sftf-defends [event-recs player-id]
  (let [sftf-defends (select-event-type event-recs "sftf_defended")
	player-takes (select-pid-from-seq sftf-defends :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-sftf-fails [event-recs player-id]
  (let [sftf-fails (select-event-type event-recs "sftf_fail")
	player-takes (select-pid-from-seq sftf-fails :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

(defn get-num-sftf-assists [event-recs player-id]
  (let [sftf-assists (select-event-type event-recs "sftf_assist")
	player-takes (select-pid-from-seq sftf-assists :player player-id)
	player-name (get-in (last player-takes) [:entry :player :name])]
    {:name player-name :value (count player-takes)}))

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

(defn rank-num-water-deaths [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-num-water-deaths dk-seq player-seq)))

(defn rank-num-lame-kills [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-num-lame-kills dk-seq player-seq)))

(defn rank-jeep-crush-damage [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-total-jeep-crush-damage dk-seq player-seq)))

(defn rank-tank-crush-damage [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-total-tank-crush-damage dk-seq player-seq)))

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

;Weapon rankings

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

(defn rank-artillery-damage [log-seq] (rank-weapon-damage log-seq artillery?))
(defn rank-bazooka-damage [log-seq] (rank-weapon-damage log-seq bazooka?))
(defn rank-russian-wep-kills [log-seq] (rank-weapon-kills log-seq russian?))
(defn rank-flamethrower-damage [log-seq] (rank-weapon-damage log-seq flame-thrower?))
(defn rank-flamethrower-dam-received [log-seq] (rank-weapon-damage-received log-seq flame-thrower?))
(defn rank-fubar-damage [log-seq] (rank-weapon-damage log-seq fubar?))
(defn rank-grenade-damage [log-seq] (rank-weapon-damage log-seq grenade?))
(defn rank-heavy-mg-kills [log-seq] (rank-weapon-kills log-seq heavy-mg?))
(defn rank-jeep-gun-kills [log-seq] (rank-weapon-kills log-seq jeep?))
(defn rank-light-mg-kills [log-seq] (rank-weapon-kills log-seq light-mg?))
(defn rank-british-wep-kills [log-seq] (rank-weapon-kills log-seq british?))
(defn rank-german-wep-kills [log-seq] (rank-weapon-kills log-seq german?))
(defn rank-pistol-kills [log-seq] (rank-weapon-kills log-seq pistol?))
(defn rank-rifle-kills [log-seq] (rank-weapon-kills log-seq rifle?))
(defn rank-tank-kills [log-seq] (rank-weapon-kills log-seq tank?))
(defn rank-american-wep-kills [log-seq] (rank-weapon-kills log-seq american?))

;Area rankings

(defn create-area-ranking [value-function area-predicate log-seq player-seq]
  (reverse (sort-by :value (doall (map #(value-function (select-hit-area log-seq area-predicate) %) player-seq)))))

(defn rank-area-kills [log-seq area-predicate]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-area-ranking get-num-kills area-predicate dk-seq player-seq)))

(defn rank-crotch-kills [log-seq] (rank-area-kills log-seq crotch?))
(defn rank-limb-kills [log-seq] (rank-area-kills log-seq limb?))
(defn rank-head-neck-kills [log-seq] (rank-area-kills log-seq head-neck?))

;Game type awards

(defn rank-num-ctf-takes [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ctf-takes event-seq player-seq)))

(defn rank-num-ctf-captures [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ctf-captures event-seq player-seq)))

(defn rank-num-ctf-returns [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ctf-returns event-seq player-seq)))

(defn rank-num-ctf-pickups [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ctf-pickups event-seq player-seq)))

(defn rank-num-dom-takes [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-dom-takes event-seq player-seq)))

(defn rank-num-dom-captures [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-dom-captures event-seq player-seq)))

(defn rank-num-dom-defends [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-dom-defends event-seq player-seq)))

(defn rank-num-dom-fails [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-dom-fails event-seq player-seq)))

(defn rank-num-dom-assists [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-dom-assists event-seq player-seq)))

(defn rank-num-ftf-steals [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ftf-steals event-seq player-seq)))

(defn rank-num-ftf-scores [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ftf-scores event-seq player-seq)))

(defn rank-num-ftf-defends [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ftf-defends event-seq player-seq)))

(defn rank-num-ftf-fails [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ftf-fails event-seq player-seq)))

(defn rank-num-ftf-assists [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-ftf-assists event-seq player-seq)))

(defn rank-num-sftf-steals [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-sftf-steals event-seq player-seq)))

(defn rank-num-sftf-scores [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-sftf-scores event-seq player-seq)))

(defn rank-num-sftf-defends [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-sftf-defends event-seq player-seq)))

(defn rank-num-sftf-fails [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-sftf-fails event-seq player-seq)))

(defn rank-num-sftf-assists [log-seq]
  (let [event-seq (get-log-type log-seq game-event?)
	player-seq (get-unique-ids-from-seq event-seq :player)]
    (create-ranking get-num-sftf-assists event-seq player-seq)))

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