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

(defn process-records [records]
  (let [map-records (filter map-record? records)
	game-records (filter game-record? records)
	event-records (filter event-record? records)]
    (flatten (filter #(not (nil? %)) [(if (> (count map-records) 0)
					(for [record map-records]
					  {:type "map" :data record}))
				      (if (> (count game-records) 0)
					{:type "game" :data (last game-records)})
				      (if (> (count event-records) 0)
					(for [record event-records]
					  {:type "event" :data record}))]))))

(defroutes cod-stats-routes
  (GET "/stats/live"
    (let [ts (parse-integer (params :ts))]
      (if (< ts (count @*game-records*))
	(json-str (process-records (drop ts @*game-records*)))
	(json-str (process-records @*game-records*)))))
	;If = to # game-records, sleep for a bit then try to send
	;Update to put game record types into its own object.  Currently in *game-records*
  (GET "/stats/start"
    (if (not (nil? (params :log)))
      (dosync (ref-set *log-file-location* (params :log))))
    (let [tailer (tail-f @*log-file-location*
			 1000 
			 process-input-line)]
      ((tailer :start))
      (str "File watching started for " @*log-file-location*))))

(defservice cod-stats-routes)