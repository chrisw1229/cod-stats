;on front-end update
  ;if no parameter
    ;send all data + number of records
  ;if parameter
    ;send all data in current set after "parameter" records
  ;send current stats

;web stuff
(ns org.stoop.codStatsServlet
  (:gen-class :extends javax.servlet.http.HttpServlet)
  (:use org.stoop.codStatsIo 
	compojure.http clojure.contrib.json.write))

(defn parse-integer [str]
  (try (Integer/parseInt str) 
       (catch NumberFormatException nfe 0)))

(defn drop-first [n s]
  (reverse (drop-last n (reverse s))))

(defn map-record? [record]
  (and (contains? record :kx)
       (contains? record :ky)
       (contains? record :dx)
       (contains? record :dy)))

(defn game-record? [record]
  (and (contains? record :map)
       (contains? record :type)
       (contains? record :time)))

(defn process-records [records]
  [{:type "ts" :data (count records)}
   {:type "map" :data (filter map-record? records)}
   {:type "game" :data (filter game-record? records)}])

(defroutes cod-stats-routes
  (GET "/stats/live"
    (let [ts (parse-integer (params :ts))]
      (if (< ts (count @*game-records*))
	(json-str (process-records (drop-first ts @*game-records*)))
	(json-str (process-records @*game-records*)))))
	;If = to # game-records, sleep for a bit then try to send
	;Update to put game record types into its own object.  Currently in *game-records*
	;(json-str [{:type "ts" :data (count @*game-records*)}
	;	   {:type "map" :data (drop-first ts @*game-records*)}
	;	   {:type "ticker" :data @*player-stats-records*}])
	;(json-str [{:type "ts" :data (count @*game-records*)}
	;	   {:type "map" :data @*game-records*}
	;	   {:type "ticker" :data @*player-stats-records*}]))))
  (GET "/stats/start"
    (if (not (nil? (params :log)))
      (dosync (ref-set *log-file-location* (params :log))))
    (let [tailer (tail-f @*log-file-location*
			 1000 
			 process-input-line)]
      ((tailer :start))
      (str "File watching started for " @*log-file-location*))))

(defservice cod-stats-routes)