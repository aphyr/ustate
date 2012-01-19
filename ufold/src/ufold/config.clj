(ns ufold.config
  (:require [ufold.core])
  (:require [ufold.server])
  (:use [ufold.client])
  (:use [ufold.streams])
  (:require [ufold.sinks])
  (:gen-class))

; A stateful DSL for expressing ufold configuration.
(def core (ufold.core/core))

; Add a TCP server
(defn tcp-server [& opts]
  (dosync
    (alter (core :servers) conj
      (ufold.server/tcp-server core (apply hash-map opts)))))

; Add streams
(defn streams [& things]
  (dosync
    (alter (core :streams) concat things)))

; Start the core
(defn start []
  (ufold.core/start core))

; Eval the config file in this context
(defn include [file]
  (binding [*ns* (find-ns 'ufold.config)]
    (load-string (slurp (or file "ufold.config")))))
