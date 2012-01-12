(ns ufold.sinks)

; Sinks take states and send them to other, better places.

; Send data to a sink
(defmulti push :type)
(defmethod push :stdout [sink state]
  (prn state))

; A sink that dumps states to stdout
(defn stdout-sink [] {:type :stdout})
