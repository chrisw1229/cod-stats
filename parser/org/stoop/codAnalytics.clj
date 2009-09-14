(ns org.stoop.codAnalytics
  (:use org.stoop.codParser org.stoop.parser org.stoop.codData))

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

(defn get-unique-weapons-from-seq [dk-seq]
  (get-unique-from-seq dk-seq [:entry :hit-details :weapon]))

;Get totals of stuff

(defn sum-over [log-seq nested-keys]
  (reduce + (doall (map #(get-in % nested-keys) log-seq))))

(defn get-total-damage-dealt [dk-seq player-name]
  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))
	player-dks (select-player-from-seq dk-good-recs :attacker player-name)]
    (sum-over player-dks [:entry :hit-details :damage])))

(defn get-total-damage-received [dk-seq player-name]
  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))
	player-dks (select-player-from-seq dk-good-recs :victim player-name)]
    (sum-over player-dks [:entry :hit-details :damage])))

(defn get-total-team-damage-dealt [dk-seq player-name]
  (let [dk-team-recs (get-log-type dk-seq team-damage?)
	player-td (select-player-from-seq dk-team-recs :attacker player-name)]
    (sum-over player-td [:entry :hit-details :damage])))

(defn get-total-team-damage-received [dk-seq player-name]
  (let [dk-team-recs (get-log-type dk-seq team-damage?)
	player-td (select-player-from-seq dk-team-recs :victim player-name)]
    (sum-over player-td [:entry :hit-details :damage])))

(defn get-num-kills [dk-seq player-name]
  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))
	k-good-recs (get-log-type dk-good-recs kill?)
	player-ks (select-player-from-seq k-good-recs :attacker player-name)]
    (count player-ks)))

(defn get-num-team-kills [dk-seq player-name]
  (let [dk-team-recs (get-log-type dk-seq team-damage?)
	tk-recs (get-log-type dk-team-recs kill?)
	player-tks (select-player-from-seq tk-recs :attacker player-name)]
    (count player-tks)))

(defn get-num-deaths [dk-seq player-name]
  (let [k-recs (get-log-type dk-seq kill?)
	player-ds (select-player-from-seq k-recs :victim player-name)]
    (count player-ds)))

(defn get-num-suicides [dk-seq player-name]
  (let [sui-recs (get-log-type dk-seq #(and (kill? %) (self-damage? %)))
	player-suis (select-player-from-seq sui-recs :attacker player-name)]
    (count player-suis)))

(defn get-total-self-damage [dk-seq player-name]
  (let [self-recs (get-log-type dk-seq self-damage?)
	player-recs (select-player-from-seq self-recs :attacker player-name)]
    (sum-over player-recs [:entry :hit-details :damage])))

(defn get-total-fall-damage [dk-seq player-name]
  (let [fall-recs (select-damage-type dk-seq "MOD_FALLING")
	player-falls (select-player-from-seq fall-recs :victim player-name)]
    (sum-over player-falls [:entry :hit-details :damage])))

(defn get-num-talks [log-seq player-name]
  (let [chat-recs (get-log-type log-seq talk?)
	player-talks (select-player-from-seq chat-recs :player player-name)]
    (count player-talks)))

;Calculate overall rankings of things

(defstruct p-v-struct :player :value)

(defn create-ranking [value-function log-seq player-seq]
  (reverse (sort-by :value (doall (map #(struct p-v-struct % (value-function log-seq %)) player-seq)))))

(defn rank-num-kills [dk-seq]
  (let [player-seq (get-unique-names-from-seq dk-seq :attacker)]
    (create-ranking get-num-kills dk-seq player-seq)))

(defn rank-total-dam-dealt [dk-seq]
  (let [player-seq (get-unique-names-from-seq dk-seq :attacker)]
    (create-ranking get-total-damage-dealt dk-seq player-seq)))

(defn rank-total-dam-received [dk-seq]
  (let [player-seq (get-unique-names-from-seq dk-seq :victim)]
    (create-ranking get-total-damage-received dk-seq player-seq)))

(defn rank-num-deaths [dk-seq]
  (let [player-seq (get-unique-names-from-seq dk-seq :victim)]
    (create-ranking get-num-deaths dk-seq player-seq)))

(defn rank-num-suicides [dk-seq]
  (let [player-seq (get-unique-names-from-seq dk-seq :attacker)]
    (create-ranking get-num-suicides dk-seq player-seq)))

(defn rank-num-talks [talk-seq]
  (let [player-seq (get-unique-names-from-seq talk-seq :player)]
    (create-ranking get-num-talks talk-seq player-seq)))

(defn rank-kills-plus-deaths [dk-seq]
  (let [player-seq (distinct (concat (get-unique-names-from-seq dk-seq :attacker)
				     (get-unique-names-from-seq dk-seq :victim)))]
    (create-ranking #(+ (get-num-kills %1 %2) (get-num-deaths %1 %2)) dk-seq player-seq)))

(defn rank-total-fall-damage [dk-seq]
  (let [player-seq (get-unique-names-from-seq dk-seq :victim)]
    (create-ranking get-total-fall-damage dk-seq player-seq)))

(defn rank-total-self-damage [dk-seq]
  (let [player-seq (get-unique-names-from-seq dk-seq :attacker)]
    (create-ranking get-total-self-damage dk-seq player-seq)))

(defn create-weapon-ranking [value-function weapon-predicate log-seq player-seq]
  (reverse (sort-by :value (doall (map #(struct p-v-struct % (value-function (select-weapon-type log-seq weapon-predicate) %)) player-seq)))))

(defn rank-weapon-damage [dk-seq weapon-predicate]
  (let [player-seq (get-unique-names-from-seq dk-seq :attacker)]
    (create-weapon-ranking get-total-damage-dealt weapon-predicate dk-seq player-seq)))

(defn rank-weapon-kills [dk-seq weapon-predicate]
  (let [player-seq (get-unique-names-from-seq dk-seq :attacker)]
    (create-weapon-ranking get-num-kills weapon-predicate dk-seq player-seq)))