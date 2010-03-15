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

(ns org.danlarkin.json
  (:import (java.io StringWriter StringReader BufferedReader))
  (:use (org.danlarkin.json [encoder :as encoder]
                            [decoder :as decoder])))

;(set! *warn-on-reflection* true)

(defmacro add-encoder
  "Macro to add custom encoding behavior to the encoder.

   For example:

   (add-encoder java.util.Date
             (fn [#^java.util.Date date #^Writer writer
                  #^String pad #^String current-indent #^String start-token-indent #^Integer indent-size]
               (.append writer (str start-token-indent \" date \"))))

   The type hinting of parameters isn't required but it does seem to speed up performance a lot
   so I recommend using them.

   "
  [type-dispatcher f]
  `(let [args# (gensym "args")]
     (defmethod encoder/encode-custom ~type-dispatcher
       [& args#]
       (apply ~f args#))))


(defn encode-to-str
  "Takes an arbitrarily nested clojure datastructure
   and returns a JSON-encoded string representation
   in a java.lang.String."
  [value & opts]
  (let [writer (StringWriter.)
        opts (apply hash-map opts)
        indent-size (get opts :indent 0)
        pad (if (> indent-size 0) \newline "")
        indent (apply str (replicate indent-size " "))]
    (str (encoder/encode-helper value writer pad "" indent-size))))

(defn encode-to-writer
  "Takes an arbitrarily nested clojure datastructure
   and a java.io.Writer and returns a JSON-encoded
   string representation in the java.io.Writer."
  [value #^Writer writer & opts]
  (let [opts (apply hash-map opts)
        indent-size (get opts :indent 0)
        pad (if (> indent-size 0) \newline "")
        indent (apply str (replicate indent-size " "))]
    (encoder/encode-helper value writer pad "" indent-size)))

(defn decode-from-reader
  "Takes a java.io.Reader pointing to JSON-encoded data and
   returns a clojure datastructure."
  [reader]
  ;; Unless we're already dealing with a BufferedReader, wrap the supplied reader in one
  ;; (this ensures we have a consistent interface supporting mark/reset regardless which
  ;; subclass of Reader we were passed).  For now, we'll use the default buffer length.
  (if (isa? reader BufferedReader)
    (decoder/decode-from-buffered-reader reader)
    (decoder/decode-from-buffered-reader (BufferedReader. reader))))

(defn decode-from-str
  "Takes a JSON-encoded string and returns a clojure datastructure."
  [value]
  (decode-from-reader (StringReader. value)))
