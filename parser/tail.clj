(defn tail-f [file delay action]
  (let [keep-running (atom true)
	thread (Thread. #(with-open [fr (java.io.FileReader. file)
				     br (java.io.BufferedReader. fr)]
			   (while @keep-running
			     (let [current-line (.readLine br)]
			       (if (not (nil? current-line))
				 (action current-line)
				 (Thread/sleep delay))))))]
    {:start #(.start thread)
     :stop #(do (reset! keep-running false)
		(.join thread)
		(println "tail-f has stopped."))}))