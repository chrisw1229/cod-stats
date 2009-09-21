;on front-end update
  ;if no parameter
    ;send all data + number of records
  ;if parameter
    ;send all data in current set after "parameter" records
  ;send current stats

;web stuff
(ns org.stoop.codStatsServlet
  (:gen-class :extends javax.servlet.http.HttpServlet)
  (:use compojure.http clojure.contrib.json.write))

(def game-records (ref []))
(def player-stats-records (ref []))

(defn parse-integer [str]
  (try (Integer/parseInt str) 
       (catch NumberFormatException nfe 0)))

(defn drop-first [n s]
  (reverse (drop-last n (reverse s))))

(defroutes cod-stats-routes
  (GET "/stats/live"
    (let [ts (parse-integer (params :ts))]
      (if (< ts (count @game-records))
	;If = to # game-records, sleep for a bit then try to send
	(json-str [{:type "ts" :data (count @game-records)}
		   {:type "map" :data (drop-first ts @game-records)}
		   {:type "ticker" :data @player-stats-records}])
	(json-str [{:type "ts" :data (count @game-records)}
		   {:type "map" :data @game-records}
		   {:type "ticker" :data @player-stats-records}])))))

(defservice cod-stats-routes)