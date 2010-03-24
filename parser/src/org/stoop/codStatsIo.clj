(ns org.stoop.codStatsIo
  (:use clojure.contrib.duck-streams org.danlarkin.json))

;File watching functions
;Watch for console_mp.log and games_mp.log.

(def *photo-info-location* (ref (str "C:/Program Files/Call of Duty/cod-stats/photos.json")))

(defn write-photo-log [photo-map]
  (spit @*photo-info-location* (encode-to-str photo-map)))

(defn read-photo-log []
  (try
   (let [photo-map (decode-from-str (slurp @*photo-info-location*))]
     (when (map? photo-map)
       (zipmap (map name (keys photo-map)) (vals photo-map))))
   (catch Exception e
     {})))

(def *log-file-location* (ref (str "C:/Program Files/Call of Duty/cod-stats/games_mp.log")))
(def *connect-log-location* (ref (str "C:/Program Files/Call of Duty/cod-stats/console_mp.log")))

(defn tail-f [file delay action]
  (let [keep-running (atom true)
	current-line (StringBuilder.)
	thread (Thread. #(try
			  (with-open[fis (java.io.FileInputStream. file)
				     bis (java.io.BufferedInputStream. fis)]
			    (while @keep-running
			      (let [input-char (.read bis)]
				(cond 
				  (= input-char -1) (Thread/sleep delay)
				  
				  (= (char input-char) \newline)
				  (do
				    (action (.toString current-line))
				    (.setLength current-line 0))
				  
				  true (.append current-line (char input-char))))))
			  (catch java.io.FileNotFoundException e
			    (println "File " file " does not exist."))
			  (catch SecurityException e
			    (println "Security denies access to " file e))
			  (catch java.io.IOException e
			    (println "Error reading file " file e))
			  (catch InterruptedException e
			    (println "Thread interrupted while reading " file e))))]
    {:start #(.start thread)
     :stop #(do (reset! keep-running false)
		(.join thread)
		(println "tail-f has stopped."))}))