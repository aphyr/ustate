(ns reimann.config
  (:require [reimann.core])
  (:require [reimann.server])
  (:use reimann.client)
  (:use reimann.streams)
  (:use reimann.email)
  (:gen-class))

; A stateful DSL for expressing reimann configuration.
(def core (reimann.core/core))

; Add a TCP server
(defn tcp-server [& opts]
  (dosync
    (alter (core :servers) conj
      (reimann.server/tcp-server core (apply hash-map opts)))))

; Add streams
(defn streams [& things]
  (dosync
    (alter (core :streams) concat things)))

; Start the core
(defn start []
  (reimann.core/start core))

; Eval the config file in this context
(defn include [file]
  (binding [*ns* (find-ns 'reimann.config)]
    (load-string (slurp (or file "reimann.config")))))
