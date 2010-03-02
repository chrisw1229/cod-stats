;web stuff
(ns org.stoop.codStatsServlet
  (:gen-class :extends javax.servlet.http.HttpServlet)
  (:use org.stoop.codStatsIo org.stoop.codStatsRealTime org.stoop.schedule
	compojure.http clojure.contrib.json.write clojure.contrib.seq-utils))

(def max-map-records 20)

(defn parse-integer [str]
  (try (Integer/parseInt str) 
       (catch NumberFormatException nfe 0)))

(defn map-record? [record]
  (or
   (and (contains? record :kx)
	(contains? record :ky)
	(contains? record :dx)
	(contains? record :dy))
   (and (contains? record :sx)
	(contains? record :sy))))

(defn game-record? [record]
  (and (contains? record :map)
       (contains? record :type)
       (contains? record :time)))

(defn event-record? [record]
  (or 
   (and (contains? record :team)
	(contains? record :time))
   (and (contains? record :time)
	(= 1 (count record)))))

(defn player-record? [record]
  (and (contains? record :name)
       (contains? record :team)))

(defn process-records [records]
  (let [map-records (filter map-record? records)
	game-records (filter game-record? records)
	event-records (filter event-record? records)
	player-records (filter player-record? records)]
    (flatten (filter #(not (nil? %)) [(when (> (count game-records) 0)
					{:type "game" :data (last game-records)})
				      
				      (when (> (count map-records) 0)
					(for [record (take max-map-records (reverse map-records))]
					  {:type "map" :data record}))
				      
				      (when (> (count event-records) 0)
					(for [record event-records]
					  {:type "event" :data record}))
				      
				      (when (> (count player-records) 0)
					(for [record player-records]
					  {:type "player" :data record}))]))))

(defroutes cod-stats-routes
  (GET "/stats/live"
    (let [ts (parse-integer (params :ts))]
      (if (<= ts (count @game-records))
	(json-str (conj (process-records (drop ts @game-records)) {:type "ts" :data (count @game-records)}))
	(json-str (conj (process-records @game-records) {:type "ts" :data (count @game-records)})))))
	
  (GET "/stats/start"
    (when (not (nil? (params :log)))
      (dosync (ref-set *log-file-location* (params :log))))
    (when (not (nil? (params :conn)))
      (dosync (ref-set *connect-log-location* (params :conn))))
    (let [log-reader (tail-f @*log-file-location* 1000 process-input-line)
	  connect-reader (tail-f @*connect-log-location* 1000 process-connect-line)]
      ;Start log readers
      ((connect-reader :start))
      ((log-reader :start))
      ;Start trend calculation to repeat once every minute
      (fixedrate {:name "Trend"
		  :task #(update-ratios player-stats-map player-id-ratio-map)
		  :start-delay 0
		  :rate 1
		  :unit (:minutes unit)})
      ;Start event heartbeat for jeep meter once every 5 seconds
      (fixedrate {:name "Heartbeat"
		  :task #(heartbeat-game-event (last @game-archive))
		  :start-delay 0
		  :rate 5
		  :unit (:seconds unit)})
      (str "File watching started for " @*log-file-location*))))

(defservice cod-stats-routes)
