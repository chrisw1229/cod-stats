;web stuff
(ns org.stoop.codStatsServlet
  (:gen-class :extends javax.servlet.http.HttpServlet)
  (:use org.stoop.codStatsIo org.stoop.codStatsRealTime
	compojure.http clojure.contrib.json.write clojure.contrib.seq-utils))

(defn parse-integer [str]
  (try (Integer/parseInt str) 
       (catch NumberFormatException nfe 0)))

(defn map-record? [record]
  (and (contains? record :kx)
       (contains? record :ky)
       (contains? record :dx)
       (contains? record :dy)))

(defn game-record? [record]
  (and (contains? record :map)
       (contains? record :type)
       (contains? record :time)))

(defn event-record? [record]
  (and (contains? record :team)
       (contains? record :time)))

(defn player-record? [record]
  (and (contains? record :name)
       (contains? record :team)))

(defn process-records [records]
  (let [map-records (filter map-record? records)
	game-records (filter game-record? records)
	event-records (filter event-record? records)
	player-records (filter player-record? records)]
    (flatten (filter #(not (nil? %)) [(if (> (count map-records) 0)
					(for [record map-records]
					  {:type "map" :data record}))
				      (if (> (count game-records) 0)
					{:type "game" :data (last game-records)})
				      (if (> (count event-records) 0)
					(for [record event-records]
					  {:type "event" :data record}))
				      (if (> (count player-records) 0)
					(for [record player-records]
					  {:type "player" :data record}))]))))

(defroutes cod-stats-routes
  (GET "/stats/live"
    (let [ts (parse-integer (params :ts))]
      (if (<= ts (count @*game-records*))
	(json-str (conj (process-records (drop ts @*game-records*)) {:type "ts" :data (count @*game-records*)}))
	(json-str (conj (process-records @*game-records*) {:type "ts" :data (count @*game-records*)})))))
	;If = to # game-records, sleep for a bit then try to send
	;Update to put game record types into its own object.  Currently in *game-records*
  (GET "/stats/start"
    (when (not (nil? (params :log)))
      (dosync (ref-set *log-file-location* (params :log))))
    (when (not (nil? (params :conn)))
      (dosync (ref-set *connect-log-location* (params :conn))))
    (let [log-reader (tail-f @*log-file-location* 1000 process-input-line)
	  connect-reader (tail-f @*connect-log-location* 1000 process-connect-line)]
      ((connect-reader :start))
      ((log-reader :start))
      ;((*ratio-calculator* :start))
      (str "File watching started for " @*log-file-location*))))

(defservice cod-stats-routes)
