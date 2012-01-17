(ns ufold.streams
  (:use ufold.common)
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
        state (ref (if (fn? init) (init) init))]
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
                  :fold +
                  :out (fn [sum] (state {:metric_f sum
                                         :service (m :service)
                                         :host (m :host)
                                         :description (m :description)}))
          } m)))

; A stream which sums its input metric_fs and divides by the time since it was
; last flushed. This isn't perfect; I'll need to enhance the stream system
; to choose definite time intervals.
(defn rate [m]
  (stream (merge {:type :immediate
                  :init (fn [] [(. System nanoTime) 0])
                  :in :metric_f
                  :fold (fn [[t0, x0], x] [t0, (+ x0 x)])
                  :out (fn [[t0, sum]]
                         (try
                           (let [t1 (. System nanoTime)
                                 rate (/ (* sum 1000000000.0) (- t1 t0))]
                             (state {:metric_f rate
                                     :service (m :service)
                                     :host (m :host)
                                     :description (m :description)}))
                           (catch java.lang.ArithmeticException e
                             '())))
          } m)))

; A stream which computes 0, 50, 99, and 100 percentile events.
; Hack hack hack hack
(defn percentiles 
  ([] (percentiles {}))
  ([m]
    (let [points (or (m :points) [0 0.5 0.95 0.99 1])]
      (stream (merge {:type :bulk
                      :init []
                      :fold (fn [events] (sorted-sample events points))}
                     m)))))

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
          value (deref state)
          init (stream :init)
          initval (if (fn? init) (init) init)]
      (ref-set state initval)
      value)))

; Realize a stream's state, clearing it in the process.
(defn flush-stream [stream]
  ((stream :out)
    (case (stream :type)
      :immediate (flush-stream-value stream)
      :bulk ((stream :fold) (flush-stream-value stream)))))

; Passes events on to children only when (field event) matches pred.
(defn where [field pred & children]
    (fn [event]
      (let [value (field event)]
        (when (case (class pred)
                java.util.regex.Pattern (re-find pred value)
                (= pred value))
          (doseq [child children]
            (child event))))))

; Transforms an event by associng a new k:v pair
(defn with [field value & children]
  (fn [event]
    (let [e (assoc event field value)]
      (doseq [child children]
        (child e)))))

; Splits stream by field.
; Every time an event arrives with a new value of field, this macro invokes
; its enclosed form to return a *new*, distinct stream for that particular
; value.
(defmacro by [field & children]
  ; new-fork is a function which gives us a new copy of our children.
  ; table is a reference which maps (field event) to a fork (or list of
  ; children).
  `(let [new-fork# (fn [] [~@children])]
     (by-fn ~field new-fork#)))

(defn by-fn [field new-fork]
  (prn "field" field)
  (prn "new-fork" (new-fork))
  (let [table (ref {})]
     (fn [event]
       (let [fork-name (field event)
             fork (dosync
                    (or ((deref table) fork-name)
                        ((alter table assoc fork-name (new-fork)) 
                           fork-name)))]
         (doseq [child fork] (child event))))))
