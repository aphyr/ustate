(ns ufold.config
  (:use protobuf)
  (:require [ufold.core])
  (:require [ufold.client])
  (:require [ufold.server])
  (:require [ufold.streams])
  (:require [ufold.sinks])
  (:gen-class))

; A stateful DSL for expressing ufold configuration.
(def core (ufold.core/core))

; Add a TCP server
(defn tcp-server [& opts]
  (dosync
    (alter (core :servers) conj
      (ufold.server/tcp-server core (apply hash-map opts)))))

; Add a stream
(defn stream [& opts]
  (dosync
    (alter (core :streams) conj 
      (ufold.streams/stream (apply hash-map opts)))))

; Add a stdout sink
(defn stdout-sink []
  (dosync
    (alter (core :sinks) conj (ufold.sinks/stdout-sink))))

; Start the core
(defn start []
  (ufold.core/start core))

; Flush streams to sinks.
(defn flushp [& opts]
  (ufold.core/flush-core core (apply hash-map opts)))

; Eval the config file in this context
(defn include [file]
  (binding [*ns* (find-ns 'ufold.config)]
    (load-string (slurp (or file "ufold.config")))))
