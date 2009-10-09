(ns org.stoop.parser
  (:use name.choi.joshua.fnparse clojure.contrib.str-utils clojure.contrib.error-kit
	[clojure.contrib.seq-utils :only [flatten]]))

(defstruct state-s :remainder :column :line)
(def remainder-a (accessor state-s :remainder))
(def apply-str (partial apply str))

(defn- nb-char [subrule]
  (invisi-conc subrule (update-info :column inc)))
(defn- b-char [subrule]
  (invisi-conc subrule (update-info :line inc) (set-info :column 0)))

(deferror parse-error [] [state message message-args]
  {:msg (str (format "Error at line %s, column %s: "
	       (:line state) (:column state))
	     (apply format message message-args))
   :unhandled (throw-msg Exception)})

(defn expectation-error-fn [expectation]
  (fn [remainder state]
    (raise parse-error state "%s expected where \"%s\" is"
      [expectation (or (first remainder) "the end of the file")])))

(def nb-char-lit (comp nb-char lit))

(def space (nb-char-lit \space))
(def tab (nb-char-lit \tab))
(def newline-lit (lit \newline))
(def return-lit (lit \return))
(def line-break (rep+ (b-char (alt newline-lit return-lit))))
(def ws (constant-semantics (rep+ (alt space tab)) :ws))
(def rest-of-line
  (complex [line-string (rep+ (nb-char (except anything (alt newline-lit return-lit))))]
    (apply-str line-string)))

(def digit-lit (lit-alt-seq "0123456789" nb-char-lit))
(def neg-lit (nb-char-lit \-))
(def semi-colon-lit (nb-char-lit \;))
(def colon-lit (nb-char-lit \:))
(def comma-lit (nb-char-lit \,))
(def backslash-lit (nb-char-lit \\))
(def not-semi-colon-lit
  (complex [character (nb-char (except anything (alt (lit \;) newline-lit return-lit)))]
    character))
(def not-colon-lit
  (complex [character (nb-char (except anything (alt (lit \:) newline-lit return-lit)))]
    character))
(def not-backslash-lit
  (complex [character (nb-char (except anything (alt (lit \\) newline-lit return-lit)))]
    character))

(def number-lit
  (alt
    (complex [number (conc (opt neg-lit) (rep+ digit-lit) (nb-char-lit \.) (rep+ digit-lit))]
      (-> number flatten apply-str Float/parseFloat))
    (complex [number (conc (opt neg-lit) (rep+ digit-lit))]
      (-> number flatten apply-str Integer/parseInt))))

(def identifier
  (semantics (rep+ not-semi-colon-lit) apply-str))

(def non-colon-string
  (semantics (rep+ not-colon-lit) apply-str))

(def non-backslash-string
  (semantics (rep+ not-backslash-lit) apply-str))

(defn parse [tokens parser]
  (let [[product state :as result] (parser (struct state-s tokens 0 0))]
    (when (nil? product) (println tokens))
    product))