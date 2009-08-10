(add-classpath "file:///c:/projects/codParser/")
(load-file "c:/Projects/codParser/test.clj")

(def p-data (parse-log "C:/Projects/codParser/logs/games_mp_gday10_raw.log"))
(def dk-seq (get-log-type p-data damage-kill?))