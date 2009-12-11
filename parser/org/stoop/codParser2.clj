(ns org.stoop.codParser2
  (:use clojure.contrib.str-utils clojure.contrib.monads))

(defn is-int? [strn]
  (try (Integer/parseInt strn)
       (catch NumberFormatException nfe false)))

(defn is-float? [strn]
  (try (Float/parseFloat strn)
       (catch NumberFormatException nfe false)))

(defn is-team? [strn]
  (contains? #{"allies" "axis" "all"} strn))

(defn get-person [str-seq]
  (let [[a b c d] str-seq]
    (cond
      (and (is-int? a) (is-int? b) (is-team? c) (not (nil? d)))
      [{:id a :num b :team c :name d} (drop 4 str-seq)]
      
      (and (is-int? a) (is-int? b) (not (nil? c)))
      [{:id a :num b :team :none :name c} (drop 3 str-seq)]

      (and (is-int? a) (not (nil? b)))
      [{:id :none :num a :team :none :name b} (drop 2 str-seq)])))

(defn get-string [str-seq]
  [(first str-seq) (rest str-seq)])

(defn get-int [str-seq]
  (if (is-int? (first str-seq))
    [(Integer/parseInt (first str-seq)) (rest str-seq)]))

(defn get-float [str-seq]
  (if (is-float? (first str-seq))
    [(Float/parseFloat (first str-seq)) (rest str-seq)]))

(defn get-location [str-seq]
  (let [[x y z] (map #(Float/parseFloat %) (re-split #"," (first str-seq)))]
    [{:x x :y y :z z} (rest str-seq)]))

(def get-hit-info (domonad state-m
			   [weapon get-string
			    damage get-float
			    type get-string
			    area get-string]
			   {:weapon weapon :damage damage :type type :area area}))

(def get-shell-shock (domonad state-m
			      [_ get-string
			       shocked-player get-person
			       shock-info get-hit-info]
			      {:shock shocked-player :shock-info shock-info}))
  

(def get-spectator (domonad state-m
			    [_ get-string
			     spec-player get-person]
			    {:spectator spec-player}))

(def get-rank (domonad state-m
		       [_ get-string
			rank-player get-person
			new-rank get-int]
		       {:player rank-player :rank new-rank}))

(def get-spawn (domonad state-m
			[_ get-string
			 spawn get-person
			 weapon get-string
			 location get-location]
			{:spawn spawn :weapon weapon :location location}))
(defn parse-time [time-string]
  (let [split-seq (re-split #":" time-string)]
    (+ (Float/parseFloat (first split-seq)) (/ (Float/parseFloat (second split-seq)) 60))))

(defn split-line [line]
  (let [split-seq (re-split #" " (.trim line) 2)]
    {:time (parse-time (first split-seq)) :entry (re-split #";" (second split-seq))}))

(defn split-log [file]
  (map split-line (re-split #"[\r*\n]+" (slurp file))))