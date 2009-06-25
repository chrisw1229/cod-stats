(use 'org.stoop.codParser 'org.stoop.parser)

(defn parse [tokens parser]
  (let [[product state :as result] (parser (struct state-s tokens 0 0))]
    (println state)
    product))

(defn parse-log [file]
  (with-open [fr (java.io.FileReader. file)
	      br (java.io.BufferedReader. fr)]
    (def parse-data #{})
    (doseq [line (line-seq br)] (def parse-data (conj parse-data (parse line log-line))))
    parse-data))

(defn get-connections [log-set]
  (clojure.set/select #(connection? (:entry %)) log-set))

(defn select-player-from-connections [connection-set name]
  (clojure.set/select #(.equalsIgnoreCase name (:name (:player (:entry %)))) connection-set))