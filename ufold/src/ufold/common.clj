(ns ufold.common
  (:use [protobuf])
  (:import [java.util Date])
  (:use [clojure.contrib.math]))

(defprotobuf Msg Ufold$Msg)
(defprotobuf State Ufold$State)
(defprotobuf Event Ufold$Event)

(defn unix-time []
  (/ (System/currentTimeMillis) 1000))

; Create a new event
(defn event [opts]
  (let [t (or (opts :time)
              (round (unix-time)))]
    (apply protobuf Event
      (apply concat (merge {:time t} opts)))))

; Create a new state
(defn state [opts]
  (let [t (or (opts :time)
              (round (unix-time)))]
    (apply protobuf State
      (apply concat (merge {:time t} opts)))))
