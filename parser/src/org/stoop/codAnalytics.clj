(ns org.stoop.codAnalytics
  (:use org.stoop.codParser org.stoop.codData))

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

(defn get-unique-weapons-from-seq [dk-seq]
  (get-unique-from-seq dk-seq [:entry :hit-details :weapon]))

;Get totals of stuff

(defn sum-over [log-seq nested-keys]
  (reduce + (doall (map #(get-in % nested-keys) log-seq))))

(defn get-total-damage-dealt [dk-seq player-id]
  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))
	player-dks (select-pid-from-seq dk-good-recs :attacker player-id)
	player-name (get-in (last player-dks) [:entry :attacker :name])]
    {:player player-name :value (sum-over player-dks [:entry :hit-details :damage])}))

(defn get-total-damage-received [dk-seq player-id]
  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))
	player-dks (select-pid-from-seq dk-good-recs :victim player-id)
	player-name (get-in (last player-dks) [:entry :victim :name])]
    {:name player-name :value (sum-over player-dks [:entry :hit-details :damage])}))

(defn get-total-team-damage-dealt [dk-seq player-id]
  (let [dk-team-recs (get-log-type dk-seq team-damage?)
	player-td (select-pid-from-seq dk-team-recs :attacker player-id)
	player-name (get-in (last player-td) [:entry :attacker :name])]
    {:name player-name :value (sum-over player-td [:entry :hit-details :damage])}))

(defn get-total-team-damage-received [dk-seq player-id]
  (let [dk-team-recs (get-log-type dk-seq team-damage?)
	player-td (select-pid-from-seq dk-team-recs :victim player-id)
	player-name (get-in (last player-td) [:entry :victim :name])]
    {:name player-name :value (sum-over player-td [:entry :hit-details :damage])}))

(defn get-num-kills [dk-seq player-id]
  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))
	k-good-recs (get-log-type dk-good-recs kill?)
	player-ks (select-pid-from-seq k-good-recs :attacker player-id)
	player-name (get-in (last player-ks) [:entry :attacker :name])]
    {:name player-name :value (count player-ks)}))

(defn get-num-team-kills [dk-seq player-id]
  (let [dk-team-recs (get-log-type dk-seq team-damage?)
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

(defn get-num-talks [chat-recs player-id]
  (let [player-talks (select-pid-from-seq chat-recs :player player-id)
	player-name (get-in (last player-talks) [:entry :player :name])]
    {:name player-name :value (count player-talks)}))

;Calculate overall rankings of things

(defn create-ranking [value-function log-seq player-seq]
  (reverse (sort-by :value (doall (map #(value-function log-seq %) player-seq)))))

(defn rank-num-kills [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-num-kills dk-seq player-seq)))

(defn rank-total-dam-dealt [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-ranking get-total-damage-dealt dk-seq player-seq)))

(defn rank-total-dam-received [log-seq]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :victim)]
    (create-ranking get-total-damage-received dk-seq player-seq)))

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

(defn create-weapon-ranking [value-function weapon-predicate log-seq player-seq]
  (reverse (sort-by :value (doall (map #(value-function (select-weapon-type log-seq weapon-predicate) %) player-seq)))))

(defn rank-weapon-damage [log-seq weapon-predicate]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-weapon-ranking get-total-damage-dealt weapon-predicate dk-seq player-seq)))

(defn rank-weapon-kills [log-seq weapon-predicate]
  (let [dk-seq (get-log-type log-seq damage-kill?)
	player-seq (get-unique-ids-from-seq dk-seq :attacker)]
    (create-weapon-ranking get-num-kills weapon-predicate dk-seq player-seq)))