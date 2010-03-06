(ns org.stoop.codIdentity
  (:use clojure.contrib.seq-utils))

(def player-id-map (ref {}))
(def name-id-map (ref {}))
(def client-id-id-map (ref {}))
(def ip-id-map (ref {}))
(def *new-id* (ref 1))

(def client-id-ip-map (ref {}))
(def *check-ip* true)

(defn associate-client-id-to-ip
  "Associates an IP address to the client ID passed in."
  [client-id ip-address]
  (dosync (alter client-id-ip-map assoc client-id ip-address)))

(defn create-new-player-id
  "Creates a new player ID to associate with name/client-id pair."
  ([name client-id]
     (do
       (dosync (alter player-id-map assoc [name client-id] @*new-id*)
	       (alter name-id-map assoc name @*new-id*)
	       (alter client-id-id-map assoc client-id @*new-id*)
	       (alter *new-id* inc))
       (dec @*new-id*)))
  ([name client-id ip-address]
     (do
       (dosync (alter player-id-map assoc [name client-id] @*new-id*)
	       (alter name-id-map assoc name @*new-id*)
	       (alter client-id-id-map assoc client-id @*new-id*)
	       (alter ip-id-map assoc ip-address @*new-id*)
	       (alter *new-id* inc))
       (dec @*new-id*))))

(defn get-player-id
  "Gets the current id associated with name/client-id combination."
  [name client-id]
  (let [player-id (get @player-id-map [name client-id])
	name-id (get @name-id-map name)
	client-id-id (get @client-id-id-map client-id)
	ip-address (get @client-id-ip-map client-id)
	ip-id (get @ip-id-map ip-address)]
    (cond
     ;Everything matches and is non-nil
     (and (not (nil? player-id))
	  (= player-id ip-id name-id client-id-id))
     player-id
     
     ;We have an ID associated with the IP address that's different (IP takes precedence)
     (not (nil? ip-id))
     (dosync (alter name-id-map assoc name ip-id)
	     (alter client-id-id-map assoc client-id ip-id)
	     (alter player-id-map assoc [name client-id] ip-id)
	     ip-id)

     ;We have a new IP address and an old name (new machine, old player case)
     (and (not (nil? ip-address)) (not (nil? name-id)))
     (dosync (alter ip-id-map assoc ip-address name-id)
	     name-id)

     ;We have a new IP address new name (new machine, new player)
     (not (nil? ip-address))
     (create-new-player-id name client-id ip-address)

     ;Perhaps we just don't have IP addresses for some reason
     (not (nil? player-id)) player-id

     ;Old player identified by name with new client ID
     (not (nil? name-id))
     (dosync (alter player-id-map assoc [name client-id] name-id)
	     (alter client-id-id-map assoc client-id name-id)
	     name-id)

     ;Old player identified by client-id (change name case)
     (not (nil? client-id-id))
     (dosync (alter player-id-map assoc [name client-id] client-id-id)
	     (alter name-id-map assoc name client-id-id)
	     client-id-id)
     
     ;No IP address and a new player
     :else
     (create-new-player-id name client-id))))

(defn inject-player-id
  [player-struct]
  (assoc player-struct :id (get-player-id (:name player-struct) (:num player-struct))))