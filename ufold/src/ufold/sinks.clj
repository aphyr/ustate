(ns ufold.sinks)

; Sinks take states and send them to other, better places.

; Send data to a sink
(defmulti push :type)
(defmethod push :stdout [sink state]
  (prn state))
(defmethod push :list [sink state]
  (dosync (alter (sink :value) conj state)))

; A sink that dumps states to stdout
(defn stdout-sink [] {:type :stdout})

; A sink that accrues values in a list ref
(defn list-sink []
  {:type :list
   :value (ref '())})
