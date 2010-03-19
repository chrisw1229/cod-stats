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

;Get totals of stuff

(defn sum-over [log-seq nested-keys]
  (reduce + (doall (map #(get-in % nested-keys) log-seq))))

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

(defn get-number-tdm-wins [log-seq player-id]
  (get-number-wins log-seq "tdm" player-id))

(defn get-number-tdm-losses [log-seq player-id]
  (get-number-losses log-seq "tdm" player-id))

(defn get-number-ctf-wins [log-seq player-id]
  (get-number-wins log-seq "ctf" player-id))

(defn get-number-ctf-losses [log-seq player-id]
  (get-number-losses log-seq "ctf" player-id))

(defn get-number-dom-wins [log-seq player-id]
  (get-number-wins log-seq "dom" player-id))

(defn get-number-dom-losses [log-seq player-id]
  (get-number-losses log-seq "dom" player-id))

(defn get-number-ftf-wins [log-seq player-id]
  (get-number-wins log-seq "ftf" player-id))

(defn get-number-ftf-losses [log-seq player-id]
  (get-number-losses log-seq "ftf" player-id))

(defn get-number-sftf-wins [log-seq player-id]
  (get-number-wins log-seq "sftf" player-id))

(defn get-number-sftf-losses [log-seq player-id]
  (get-number-losses log-seq "sftf" player-id))

;Calculate overall rankings of things

(defn create-ranking [value-function log-seq player-seq]
  (reverse (sort-by :value (doall (map #(value-function log-seq %) player-seq)))))

(defn rank-num-tdm-wins [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-tdm-wins log-seq player-seq)))

(defn rank-num-tdm-losses [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-tdm-losses log-seq player-seq)))

(defn rank-num-ctf-wins [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-ctf-wins log-seq player-seq)))

(defn rank-num-ctf-losses [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-ctf-losses log-seq player-seq)))

(defn rank-num-dom-wins [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-dom-wins log-seq player-seq)))

(defn rank-num-dom-losses [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-dom-losses log-seq player-seq)))

(defn rank-num-ftf-wins [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-ftf-wins log-seq player-seq)))

(defn rank-num-ftf-losses [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-ftf-losses log-seq player-seq)))

(defn rank-num-sftf-wins [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-sftf-wins log-seq player-seq)))

(defn rank-num-sftf-losses [log-seq]
  (let [join-seq (get-log-type log-seq join?)
	player-seq (get-unique-ids-from-seq join-seq :player)]
    (create-ranking get-number-sftf-losses log-seq player-seq)))

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

(defn get-leaderboard-stats [player-id dk-seq]
  (let [kill-results (get-num-kills dk-seq player-id)
	death-results (get-num-deaths dk-seq player-id)
	suicide-results (get-num-suicides dk-seq player-id)
	inflicted-results (get-total-damage-dealt dk-seq player-id)
	received-results (get-total-damage-received dk-seq player-id)]
    (list (:name kill-results)
	  (:value kill-results)
	  (:value death-results)
	  (:value suicide-results)
	  20 ;time played
	  (:value inflicted-results)
	  (:value received-results)
	  "Best Weapon"
	  "Best Enemy")))

(defn get-all-leaderboard-stats [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-ids (get-all-ids dk-seq)]
    (filter #(not (nil? %))
	    (for [player-id player-ids]
	      (let [leader-stats (get-leaderboard-stats player-id dk-seq)]
		(when (not (nil? (first leader-stats)))
		  leader-stats))))))