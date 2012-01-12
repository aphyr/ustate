(ns ufold.core
  (:use protobuf)
  (:require ufold.sinks)
  (:require ufold.streams))

(defprotobuf Msg Ufold$Msg)
(defprotobuf State Ufold$State)

; A core binds together servers, streams, and clients.
; Create a new core
(defn core []
  {:servers (ref [])
   :streams (ref [])
   :flushers (ref [])
   :sinks (ref [])})

; A flusher periodically flushes streams to sinks.
(defn flusher [o]
  (.start (Thread. (fn []
    (loop []
      (Thread/sleep (* 1000 (o :every)))
      (doseq [stream (deref (o :streams))
              sink (deref (o :sinks))]
        (ufold.sinks/push sink (ufold.streams/flush-stream stream)))
      (recur))))))

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

(defn stop [core])
