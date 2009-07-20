(use 'org.stoop.codParser 'org.stoop.parser 'clojure.contrib.json.write 'clojure.contrib.duck-streams)(defn write-award [file award-name award-data]  (spit file (str (json-str {:award award-name}) (json-str award-data))))(defn get-log-type [log-seq predicate]  (filter #(predicate (:entry %)) log-seq))(defn select-player-from-seq [log-seq name-field name]  (filter #(.equalsIgnoreCase name (get-in % [:entry name-field :name])) log-seq))(defn get-unique-names-from-seq [log-seq name-field]  (distinct (doall (map #(get-in % [:entry name-field :name]) log-seq))))(defn get-unique-weapons-from-seq [dk-seq]  (distinct (doall (map #(get-in % [:entry :hit-details :weapon]) dk-seq))))(defn get-total-damage-dealt [dk-seq player-name]  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))	player-dks (select-player-from-seq dk-good-recs :attacker player-name)]    (reduce + (doall (map #(get-in % [:entry :hit-details :damage]) player-dks)))))(defn get-total-damage-received [dk-seq player-name]  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))	player-dks (select-player-from-seq dk-good-recs :victim player-name)]    (reduce + (doall (map #(get-in % [:entry :hit-details :damage]) player-dks)))))(defn get-total-team-damage-dealt [dk-seq player-name]  (let [dk-team-recs (get-log-type dk-seq team-damage?)	player-td (select-player-from-seq dk-team-recs :attacker player-name)]))(defn get-total-team-damage-received [dk-seq player-name]  (let [dk-team-recs (get-log-type dk-seq team-damage?)	player-td (select-player-from-seq dk-team-recs :victim player-name)]))(defn get-num-kills [dk-seq player-name]  (let [dk-good-recs (get-log-type dk-seq #(not (team-damage? %)))	k-good-recs (get-log-type dk-good-recs kill?)	player-ks (select-player-from-seq k-good-recs :attacker player-name)]    (count player-ks)))(defn get-num-team-kills [dk-seq player-name]  (let [dk-team-recs (get-log-type dk-seq team-damage?)	tk-recs (get-log-type dk-team-recs kill?)	player-tks (select-player-from-seq tk-recs :attacker player-name)]    (count player-tks)))(defn get-num-deaths [dk-seq player-name]  (let [k-recs (get-log-type dk-seq kill?)	player-ds (select-player-from-seq k-recs :victim player-name)]    (count player-ds)))(defn get-num-suicides [dk-seq player-name]  (let [sui-recs (get-log-type dk-seq #(and (kill? %) (self-damage? %)))	player-suis (select-player-from-seq sui-recs :attacker player-name)]    (count player-suis)))(defstruct p-v-struct :player :value)(defn rank-num-kills [dk-seq]  (let [player-seq (remove nil? (get-unique-names-from-seq dk-seq :attacker))]    (reverse (sort-by :value (doall (map #(struct p-v-struct % (get-num-kills dk-seq %)) player-seq))))))(defn rank-total-dam-dealt [dk-seq]  (let [player-seq (remove nil? (get-unique-names-from-seq dk-seq :attacker))]    (reverse (sort-by :value (doall (map #(struct p-v-struct % (get-total-damage-dealt dk-seq %)) player-seq))))))(defn rank-total-dam-received [dk-seq]  (let [player-seq (remove nil? (get-unique-names-from-seq dk-seq :victim))]    (reverse (sort-by :value (doall (map #(struct p-v-struct % (get-total-damage-received dk-seq %)) player-seq))))))(defn rank-total-deaths [dk-seq]  (let [player-seq (remove nil? (get-unique-names-from-seq dk-seq :victim))]    (reverse (sort-by :value (doall (map #(struct p-v-struct % (get-num-deaths dk-seq %)) player-seq))))))(defn rank-total-suicides [dk-seq]  (let [player-seq (remove nil? (get-unique-names-from-seq dk-seq :attacker))]    (reverse (sort-by :value (doall (map #(struct p-v-struct % (get-num-suicides dk-seq %)) player-seq))))))