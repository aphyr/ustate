(ns ufold.streams
  (:use ufold.folds))

; A stream is a specific transformation applied to a series of events,
; eventually producing a state.
; pred: determines whether a given event should be accepted
; type: one of :immediate or :bulk
;       immediate calls fold continuously as (fold accumulator, new)
;       bulk calls fold with a sequence of values (fold seq)
; init: The default value for folding into.
; in: maps an event to an intermediate representation for fold. Optional.
; fold: folds intermediate representations together
; out: maps the results of fold to a state
; state: a reference to the current value of the stream.
(defstruct stream-struct :pred :type :init :in :fold :out :state)

; Create a stream
(defn stream [m]
  (let [pred (fn [_] true)
        t :immediate
        init (or (m :init) '())
        in identity
        fold conj
        out identity
        state (ref init)]
    (apply struct-map stream-struct
           (mapcat identity
                   (merge {
                     :pred pred
                     :type t
                     :init init
                     :in in
                     :fold fold
                     :out out
                     :state state
                    } m)))))

; A stream which sums its input metric_fs
(defn sum [m]
  (stream (merge {:type :immediate
                     :init 0
                     :in :metric_f
                     :fold +} m)))

; A stream which computes 50, 99, and 100 percentile metrics
(defn percentiles [m]
  (stream (merge {:type :bulk
                     :init []
                     :fold (fn [events]
                             (sorted-sample events [0 50 95 99 100]))} m)))

; Sends an event to a stream right away
(defn apply-stream-immediate [stream event]
  (let [in    (stream :in)
        fold  (stream :fold)
        value (in event)]
    (dosync
      (alter (stream :state) fold value))))

; Send an event to a stream for later processing
(defn apply-stream-bulk [stream event]
  (let [in    (stream :in)
        value (in event)]
    (dosync
      (alter (stream :state) conj value))))

; Send an event to a stream
(defn apply-stream [stream event]
  (when ((stream :pred) event)
    (case (stream :type)
      :immediate (apply-stream-immediate stream event)
      :bulk (apply-stream-bulk stream event))))

; Send an event to several streams
(defn apply-streams [streams event]
  (doseq [s streams] (apply-stream s event)))

; Returns the stream's state and reinitializes the state
(defn flush-stream-value [stream]
  (dosync
    (let [state (stream :state)
          value (deref state)]
      (ref-set state (stream :init))
      value)))

; Realize a stream's state, clearing it in the process.
(defn flush-stream [stream]
  ((stream :out)
    (case (stream :type)
      :immediate (flush-stream-value stream)
      :bulk ((stream :fold) (flush-stream-value stream)))))
