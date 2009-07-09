(use 'org.stoop.codParser 'org.stoop.parser)(defn parse [tokens parser]  (let [[product state :as result] (parser (struct state-s tokens 0 0))]    (println state)    product))(defn parse-log [file]  (parse (slurp file) log-file))(defn get-log-type [log-seq predicate]  (filter #(predicate (:entry %)) log-seq))(defn select-player-from-seq [log-seq name-field name]  (filter #(.equalsIgnoreCase name (:name (name-field (:entry %)))) log-seq))(defn get-unique-names-from-seq [log-seq name-field]  (distinct (doall (map #(do (:name (name-field (:entry %)))) log-seq))))(defn get-total-damage [log-seq player-name]  (let [dk-recs (get-log-type log-seq damage-kill?)	dk-good-recs (get-log-type dk-recs #(not (team-damage? %)))	player-dks (select-player-from-seq dk-good-recs :attacker player-name)]    (reduce + (doall (map #(do (:damage (:hit-details (:entry %)))) player-dks)))))(defn get-num-kills [log-seq player-name]  (let [dk-recs (get-log-type log-seq damage-kill?)	dk-good-recs (get-log-type dk-recs #(not (team-damage? %)))	k-good-recs (get-log-type dk-good-recs kill?)	player-ks (select-player-from-seq k-good-recs :attacker player-name)]    (count player-ks)))