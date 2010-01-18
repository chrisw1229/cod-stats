(ns org.stoop.codStatsIo
  (:use clojure.contrib.json.write clojure.contrib.duck-streams))

;Award related functions

(defn write-award [file award-name award-data]
  (spit file (json-str {:award award-name :data award-data})))

;File watching functions

;Have some kind of loop to watch for the file to be created then start reading it in and processing.
;Watch for console_mp.log and games_mp.log.

(def *log-file-location* (ref (str "C:/Program Files/Call of Duty/cod-stats/games_mp.log")))

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
				    (println (.toString current-line))
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