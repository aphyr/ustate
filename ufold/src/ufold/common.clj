(ns ufold.common
  (:use [protobuf])
  (:import [java.util Date])
  (:use [clojure.contrib.math]))

(defprotobuf Msg Ufold$Msg)
(defprotobuf State Ufold$State)
(defprotobuf Event Ufold$Event)

; Create a new event
(defn event [opts]
  (let [t (or (opts :time)
              (round (/ (System/currentTimeMillis) 1000)))]
    (apply protobuf Event
      (apply concat (merge {:time t} opts)))))

; Create a new state
(defn state [opts]
  (let [t (or (opts :time)
              (round (/ (System/currentTimeMillis) 1000)))]
    (apply protobuf State
      (apply concat (merge {:time t} opts)))))
