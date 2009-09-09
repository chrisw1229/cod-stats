(defn tail-f [file delay action]
  (let [keep-running (atom true)]
    {:start #(with-open [fr (java.io.FileReader. file)
			 br (java.io.BufferedReader. fr)]
	       (while @keep-running
		 (let [current-line (.readLine br)]
		   (if (not (nil? current-line))
		     (action current-line)
		     (Thread/sleep delay)))))
     :stop #(reset! keep-running false)}))

(defn watch-file [file]
  (let [file-watcher (tail-f file 1000 println)
	thread (Thread. #(((file-watcher :start))))]
    (.start thread)))
;Figure out how to return the file-watcher so I can call stop later