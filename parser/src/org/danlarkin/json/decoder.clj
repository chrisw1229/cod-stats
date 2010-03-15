;; Copyright (c) 2008 Dan Larkin
;; All rights reserved.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. The name of the author may not be used to endorse or promote products
;;    derived from this software without specific prior written permission.

;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
;; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
;; OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
;; IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
;; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;; NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
;; THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(ns org.danlarkin.json.decoder
  (:import (java.io BufferedReader)))

(declare decode-value)   ;decode-value is used before it's defined
                         ;so we have to pre-define it

(defn- json-ws?
  "Returns true if the Unicode codepoint is an 'insignificant whitespace' per the JSON
   standard, false otherwise.  Cf. RFC 4627, sec. 2)"
  [#^Integer codepoint]
  (cond
   (= codepoint 0x20) true ; Space
   (= codepoint 0x09) true ; Horizontal tab
   (= codepoint 0x0A) true ; Line feed or New line
   (= codepoint 0x0D) true ; Carriage return
   :else false))

(defn- number-char?
  "Returns true if the Unicode codepoint is allowed in a number.  Cf. RFC 4627, sec. 2.4)"
  [#^Integer codepoint]
  (cond
   (and (>= codepoint 0x30) (<= codepoint 0x39)) true ; 0-9
   (= codepoint 0x2e) true ; .
   (or (= codepoint 0x65) (= codepoint 0x45)) true ; e E
   (= codepoint 0x2d) true ; -
   (= codepoint 0x2b) true ; +
   :else false))

(defn- read-matching
  "Reads and returns a string containing 0 or more characters matching match-fn from
   a BufferedReader."
  [#^BufferedReader b-reader match-fn]
  (loop [s ""]
    (let [_ (.mark b-reader 1)
          codepoint (.read b-reader)]
      (cond
       (= codepoint -1) s
       (match-fn codepoint) (recur (str s (char codepoint)))
       :else (let [_ (.reset b-reader)] s)))))

(defn- eat-whitespace
  "Reads 0 or more whitespace characters from a BufferedReader.
   Returns the whitespace eaten, not that anyone cares."
  [#^BufferedReader b-reader]
  (read-matching b-reader json-ws?))

(defn- decode-object
  "Decodes a JSON object and returns a hash-map."
  [#^BufferedReader b-reader]
  (loop [object {}]
    (let [_ (.mark b-reader 1)
          codepoint (.read b-reader)]
      (cond
       (= codepoint 0x7D) object ; }
       (= codepoint 0x2C) (recur object)
       (json-ws? codepoint) (let [_ (eat-whitespace b-reader)] (recur object))
       :else (let [_ (.reset b-reader)
                   _ (eat-whitespace b-reader)
                   key (decode-value b-reader)
                   _ (eat-whitespace b-reader)
                   name-sep (.read b-reader) ; should be : (0x3A)
                   _ (eat-whitespace b-reader)
                   value (decode-value b-reader)
                   _ (eat-whitespace b-reader)]
               (when-not (= name-sep 0x3A)
                 (throw (Exception. "Error parsing object: colon not where expected.")))
               (recur (assoc object (keyword key) value)))))))

(defn- decode-array
  "Decodes a JSON array and returns a vector."
  [#^BufferedReader b-reader]
  (loop [array []]
    (let [_ (.mark b-reader 1)
          codepoint (.read b-reader)]
      (cond
       (= codepoint 0x5D) array
       (= codepoint 0x2C) (recur array)
       ;; next case handles empty array with whitespace between [ and ]
       (json-ws? codepoint) (let [_ (eat-whitespace b-reader)] (recur array))
       :else (let [_ (.reset b-reader)
                   _ (eat-whitespace b-reader)
                   value (decode-value b-reader)
                   _ (eat-whitespace b-reader)]
               (recur (conj array value)))))))

(def unescape-map
     #^{:private true}
     {0x22 \"
      0x5C \\
      0x2F \/
      0x62 \u0008
      0x66 \u000C
      0x6E \newline
      0x72 \u000D
      0x74 \u0009})

(defn- unescape
  "We've read a backslash, now figure out what character it was escaping and return
   it."
  [#^BufferedReader b-reader]
  (let [codepoint (.read b-reader)
        map-value (unescape-map codepoint)]
    (cond
     map-value map-value
     (= codepoint 0x75)
       (read-string (str
                     "\\u"
                     (apply str (take 4 (map
                                         #(char (.read #^BufferedReader %))
                                         (repeat b-reader)))))))))

(defn- decode-string
  "Decodes a JSON string and returns it.  NOTE: strings are terminated by a double-quote
   so we won't have to worry about back-tracking."
  [#^BufferedReader b-reader]
  (loop [s ""]
    (let [codepoint (.read b-reader)]
      (cond
       (= codepoint -1) (throw (Exception. "Hit end of input inside a string!"))
       (= codepoint 0x22) s ; done (and we ate the close double-quote already)
       (= codepoint 0x5C) (recur (str s (unescape b-reader))) ; backslash escape sequence
       :else (recur (str s (char codepoint)))))))

(defn- decode-const
  "Decodes an expected constant, throwing an exception if the buffer contents don't
   match the expectation.  Otherwise, the supplied constant value is returned."
  [#^BufferedReader b-reader #^String expected value]
  (let [exp-len (count expected)
        got (loop [s "" br b-reader len exp-len]
              (if (> len 0)
                (recur (str s (char (.read br))) br (dec len))
                s))]
    (if (= got expected)
      value
      (throw (Exception. (str
                          "Unexpected constant remainder: " got
                          " expected: " expected))))))

(defn- decode-number
  "Decodes a number and returns it.  NOTE: first character of the number has already
   read so the first thing we need to do is reset the BufferedReader."
  [#^BufferedReader b-reader]
  (let [_ (.reset b-reader)
        number-str (read-matching b-reader number-char?)]
    (read-string number-str)))

(defn- decode-value
  "Decodes and returns a value (string, number, boolean, null, object, or array).
   NOTE: decode-value is not responsible for eating whitespace after the value."
  [#^BufferedReader b-reader]
  (let [_ (.mark b-reader 1)
        int-char (.read b-reader)
        char (and (not= -1 int-char) (char int-char))]
    (cond
     (= char \{) (decode-object b-reader)
     (= char \[) (decode-array b-reader)
     (= char \") (decode-string b-reader)
     (= char \f) (decode-const b-reader "alse" false)
     (= char \t) (decode-const b-reader "rue" true)
     (= char \n) (decode-const b-reader "ull" nil)
     :else (if (= -1 int-char)
             ""
             (decode-number b-reader)))))

(defn decode-from-buffered-reader
  [#^BufferedReader reader]
  (eat-whitespace reader) ; eat leading whitespace; next char should
  (decode-value reader))  ; be start of a value (what we'll return)
