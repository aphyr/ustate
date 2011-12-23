(ns ufold.core
  (:use clojure.contrib.logging)
  (:use protobuf))

(defprotobuf Msg Ufold$Msg)
(defprotobuf State Ufold$State)
