(ns org.stoop.codIdentity)

(def *player-id-map* (ref {}))
(def *name-id-map* (ref {}))
(def *client-id-ip-map* (ref {}))
(def *ip-id-map* (ref {}))
(def *new-id* (ref 1))

(defn associate-client-id-to-ip
  "Associates an IP address to the client ID passed in."
  [client-id ip-address]
  (dosync (alter *client-id-ip-map* assoc client-id ip-address)))

(defn create-new-player-id [name client-id]
  "Creates a new player ID to associate with name/client-id pair."
  (let [ip-address (get @*client-id-ip-map* client-id)]
    (dosync (alter *player-id-map* assoc [name client-id] @*new-id*)
	    (alter *name-id-map* assoc name @*new-id*)
	    (when (not (nil? ip-address))
	      (alter *ip-id-map* assoc (get @*client-id-ip-map* client-id) @*new-id*))
	    (alter *new-id* inc))
    (dec @*new-id*)))

(defn get-player-id
  "Gets the current id associated with name/client-id combination.

If the name/client-id pair is not associated with an ID, a search will be done first to see if there is
an ID that has been associated with the IP and that will be returned along with associating the current
name/client-id pair to that ID.

If no ID is associated with the IP, a search will be done to see if there is an ID that is associated
with the name and that ID will be returned along with associating the current name/client-id pair to
that ID.

If no name or client-id is found to be a match, a new ID will be generated and associated with the
client-id/name pair."
  [name client-id]
  (let [player-id (get @*player-id-map* [name client-id])]
    (if player-id
      (do player-id)
      (let [ip-address (get @*client-id-ip-map* client-id)
	    player-id (get @*ip-id-map* ip-address)]
	(if player-id
	  (do player-id)
	  (let [player-id (get @*name-id-map* name)]
	    (if player-id
	      (do (dosync (alter *player-id-map* assoc [name client-id] player-id)
			  (alter *client-id-id-map* assoc client-id player-id)) 
		  player-id)
	      (create-new-player-id name client-id))))))))