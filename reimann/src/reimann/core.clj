(ns reimann.core
  (:require [reimann.streams])
  (:require [reimann.index :as index]))

; This will probably come into play more when I work on hot reloading.

; Create a new core
(defn core []
  {:servers (ref [])
   :streams (ref [])
   :index   (ref nil)
   :reaper  (ref nil)})

(defn periodically-expire [core interval]
  "Every interval (default 10) seconds, expire states from this core's index
  and stream them to streams, with state \"expired\"."
  (let [interval (* 1000 (or interval 10))]
    (future (loop []
              (Thread/sleep interval)
              (let [i       (deref (:index core))
                    streams (deref (:streams core))]
                (when i
                  (doseq [state (index/expire i)
                         stream streams]
                    (stream (assoc state :state "expired")))))
              (recur)))))

(defn start [core]
  (dosync
    (when-not (deref (:reaper core))
      (ref-set (:reaper core) (periodically-expire core)))))

(defn stop [core]
  ; Stop expiry
  (when-let [r (deref (:reaper core))]
    (future-cancel r))

  ; Stop each server
  (doseq [server (deref (core :servers))]
    (server)))
