(ns reimann.core
  (:require [reimann.streams]))

; This will probably come into play more when I work on hot reloading.

; Create a new core
(defn core []
  {:servers (ref [])
   :streams (ref [])})

(defn start [core])

(defn stop [core]
  ; Stop each server
  (doseq [server (deref (core :servers))]
    (server)))
