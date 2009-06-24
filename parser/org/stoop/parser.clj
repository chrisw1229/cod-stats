(ns org.stoop.parser
  (:use name.choi.joshua.fnparse clojure.contrib.str-utils 
	[clojure.contrib.seq-utils :only [flatten]]))

(defstruct state-s :remainder :column :line)
(def remainder-a (accessor state-s :remainder))
(def apply-str (partial apply str))

(defn- nb-char [subrule]
  (invisi-conc subrule (update-info :column inc)))
(defn- b-char [subrule]
  (invisi-conc subrule (update-info :line inc)))

(def nb-char-lit (comp nb-char lit))

(def space (nb-char-lit \space))
(def tab (nb-char-lit \tab))
(def newline-lit (lit \newline))
(def return-lit (lit \return))
(def line-break (b-char (rep+ (alt newline-lit return-lit))))
(def ws (constant-semantics (rep* (alt space tab line-break)) :ws))
(def rest-of-line
  (complex [line-string get-remainder]
    (apply-str line-string)))

(def digit-lit (lit-alt-seq "0123456789" nb-char-lit))
(def semi-colon-lit (nb-char-lit \;))
(def colon-lit (nb-char-lit \:))
(def not-semi-colon-lit
  (complex [character (nb-char (except anything (lit \;)))]
    character))
(def not-colon-lit
  (complex [character (nb-char (except anything (lit \:)))]
    character))

(def number-lit
  (alt
    (complex [number (conc (rep+ digit-lit) (nb-char-lit \.) (rep+ digit-lit))]
      (-> number flatten apply-str Float/parseFloat))
    (complex [number (rep+ digit-lit)]
      (-> number apply-str Integer/parseInt))))

(def identifier
  (semantics (rep+ not-semi-colon-lit) apply-str))

(def non-colon-string
  (semantics (rep+ not-colon-lit) apply-str))