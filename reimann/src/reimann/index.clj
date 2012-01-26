(ns reimann.index)

; The index accepts states and maintains a table of the most recent state for each unique [host, service].

(defrecord Index [table]
  (clear [this]
         "Wipe all states"
         (.clear (:table this)))

  (update [this state]
          "Update this index with the given state."
          (.put (:table this)
                [(:host state) (:service state)]
                state)))
