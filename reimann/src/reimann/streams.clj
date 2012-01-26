(ns reimann.streams
  (:use reimann.common)
  (:use reimann.folds)
  (:require [reimann.client])
  (:use [clojure.contrib.math])
  (:use [clojure.contrib.logging]))

; Call each fn, in order, with event. Rescues and logs any failure.
(defmacro call-rescue [event children]
  `(doseq [child# ~children]
     (try
       (child# ~event)
       (catch Exception e#
         (log :warn (str child# " threw") e#)))))

; On my MBP tops out at around 300K
; events/sec. Experimental benchmarks suggest that:
(comment (time
             (doseq [f (map (fn [t] (future
               (let [c (ref 0)]
                 (dotimes [i (/ total threads)]
                         (let [e {:metric_f 1 :time (unix-time)}]
                           (dosync (commute c + (:metric_f e))))))))
                            (range threads))]
               (deref f))))
; can do something like 1.9 million events/sec over 4 threads.  That suggests
; there's a space for a faster (but less correct) version which uses either
; agents or involves fewer STM ops. Assuming all events have local time might
; actually be more useful than correctly binning/expiring multiple times.
; Also: broken?
(defn part-time-fn [interval create add finish]
  ; All intervals are [start, end)
  (let [; The oldest time we are allowed to flush rates for.
        watermark (ref 0)
        ; A list of all bins we're tracking.
        bins (ref {})
        ; Eventually finish a bin.
        finish-eventually (fn [bin start]
          (.start (new Thread (fn []
                         (let [end (+ start interval)]
                           ; Sleep until this bin is past
                           (Thread/sleep (max 0 (* 1000 (- end (unix-time)))))
                           ; Prevent anyone else from creating or changing this
                           ; bin. Congratulations, you've invented timelocks.
                           (dosync
                             (alter bins dissoc start)
                             (alter watermark max end))
                           ; Now that we're safe from modification, finish him!
                           (finish bin start end))))))
        
        ; Add event to the bin for a time
        bin (fn [event t]
              (let [start (quot t interval)]
                (dosync
                  (when (<= (deref watermark) start)
                    ; We are accepting this event.
                    ; Return an existing table
                    ; or create and store a new one
                    (let [current ((deref bins) start)]
                      (if current
                        ; Use current
                        (add current event)
                        ; Create new
                        (let [bin (create event)]
                          (alter bins assoc start bin)
                          (finish-eventually bin start))))))))]

    (fn [event]
      (let [; What time did this event happen at?
            t (or (event :time) (unix-time))]
        (bin event t)))))

; Partitions events by time (fast variant). Over interval seconds, adds events
; to a bin, created with (create). When the interval is complete, calls (finish
; bin start-time end-time)
;
; This leaks a thread. Need to think about dynamic scheduling/expiry.
(defn part-time-fast [interval create add finish]
  (let [current (ref (create))
        start (ref (unix-time))
        switcher (.start (new Thread (bound-fn []
          ; Switch between bins
          (loop [] 
            ; Wait for interval
            (Thread/sleep (* interval 1000))
            ; Switch out old bin, create new one, call finish on old bin.
            (apply finish
                   (dosync
                     (let [bin (deref current)
                           old-start (deref start)
                           boundary (unix-time)]
                       (ref-set start boundary)
                       (ref-set current (create))
                       [bin old-start boundary])))
            (recur)))))]
    (fn [event]
      (dosync
        (add (deref current) event)))))

; Take the sum of every event over interval seconds and divide by the interval
; size.
(defn rate [interval & children]
  (part-time-fast interval
      (fn [] {:count (ref 0)
              :state (ref {})})
      (fn [r event] (dosync
                      (ref-set (:state r) event)
                      (alter (:count r) + (:metric_f event))))
      (fn [r start end]
        (let [event (dosync
                (let [count (deref (r :count))
                      rate (/ count (- end start))]
                  (merge (deref (:state r)) 
                         {:metric_f rate :time (round end)})))]
          (call-rescue event children)))))

(defn percentiles [interval points & children]
  (part-time-fast interval
                (fn [] (ref []))
                (fn [r event] (dosync (alter r conj event)))
                (fn [r start end]
                  (let [samples (dosync
                                  (sorted-sample (deref r) points))]
                    (doseq [event samples] (call-rescue event children))))))

; Sums all metric_fs together. Emits the most recent event each time this stream
; is called, but with summed metric_f.
(defn sum [& children]
  (let [sum (ref 0)]
    (fn [event]
      (let [s (dosync (commute sum + (:metric_f event)))
            event (assoc event :metric_f s)]
        (call-rescue event children)))))

; Emits the most recent event each time this stream is called, but with the
; average of all received metric_fs.
(defn mean [children]
  (let [sum (ref nil)
        total (ref 0)]
    (fn [event]
      (let [m (dosync 
                (let [t (commute total inc)
                      s (commute sum + (:metric_f event))]
                  (/ s t)))
            event (assoc event :metric_f m)]
        (call-rescue event children)))))

; Conj events onto the given reference
(defn append [reference]
  (fn [event]
    (dosync
      (alter reference conj event))))

; Set reference to the most recent event that passes through.
(defn register [reference]
  (fn [event]
    (dosync (ref-set reference event))))

; Prints an event to stdout
(defn stdout [event]
  (fn [event]
    (prn event)))

; Sends a map to a client, coerced to state
(defn fwd [client]
  (fn [statelike]
    (reimann.client/send-state client statelike)))

; Passes events on to children only when (field event) matches pred.
(defn where [field pred & children]
    (fn [event]
      (let [value (field event)]
        (when (if (= (class pred) java.util.regex.Pattern)
                (re-find pred value)
                (= pred value))
          (call-rescue event children)))))

; Transforms an event by associng a set of new k:v pairs
(defmulti with (fn [& args] (map? (first args))))
(defmethod with true [m & children]
  (fn [event]
;    Merge on protobufs is broken; nil values aren't applied.
;    (let [e (merge event m)]
    (let [e (reduce (fn [m, [k, v]]
                      (if (nil? v) (dissoc m k) (assoc m k v)))
                    event m)]
      (call-rescue e children))))
(defmethod with false [k v & children]
  (fn [event]
;    (let [e (assoc event k v)]
    (let [e (if (nil? v) (dissoc event k) (assoc event k v))]
      (call-rescue e children))))

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
  (let [table (ref {})]
     (fn [event]
       (let [fork-name (field event)
             fork (dosync
                    (or ((deref table) fork-name)
                        ((alter table assoc fork-name (new-fork)) 
                           fork-name)))]
         (call-rescue event fork)))))

; Passes on events only when (f event) differs from that of the previous event.
(defn changed [pred & children]
  (let [previous (ref nil)]
    (fn [event]
      (when
        (dosync
          (let [cur (pred event) 
                old (deref previous)]
            (when-not (= cur old)
              (ref-set previous cur)
              true)))
        (call-rescue event children)))))

; Passes on events only when their metric falls within the given inclusive
; range. (within [0 1] (fn [event] do-something))
(defn within [r & children]
  (fn [event]
    (when (<= (first r) (:metric_f event) (last r))
      (call-rescue event children))))

(defn without [r & children]
  "Passes on events only when their metric falls outside the given (inclusive) range."
  (fn [event]
    (when (not (<= (first r) (:metric_f event) (last r)))
      (call-rescue event children))))

(defn over [x & children]
  "Passes on events only when their metric is greater than x"
  (fn [event]
    (when (< x (:metric_f event))
      (call-rescue event children))))

(defn under [x & children]
  "Passes on events only when their metric is smaller than x"
  (fn [event]
    (when (> x (:metric_f event))
      (call-rescue event children))))

