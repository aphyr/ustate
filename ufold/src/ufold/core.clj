(ns ufold.core
  (:use [protobuf])
  (:require [ufold.sinks])
  (:require [ufold.streams]))

; A core binds together servers, streams, and clients.
; Create a new core
(defn core []
  {:servers (ref [])
   :streams (ref [])
   :flushers (ref [])
   :sinks (ref [])})

; Flush a stream to a sink
(defn flush-stream-sink [stream sink]
  (ufold.sinks/push sink (ufold.streams/flush-stream stream)))

; A flusher periodically flushes streams to sinks.
(defn flusher [o]
  (future (loop [] (do
      (Thread/sleep (* 1000 (o :every)))
      (doseq [stream (deref (o :streams))
              sink (deref (o :sinks))]
        (flush-stream-sink stream sink))
      (recur)))))

; Adds a new flusher to this core.
(defn flush-core [core opts]
  (dosync
    (alter (core :flushers) conj
      (flusher (merge
        {:every 10
         :streams (core :streams)
         :sinks (core :sinks)}
        opts)))))

(defn start [core])

(defn stop [core]
  ; Stop each server
  (doseq [server (deref (core :servers))]
    (server))

  ; Stop each flusher
  (doseq [flusher (deref (core :flushers))]
    (future-cancel flusher)))
