(ns ufold.folds)

;; Ufold transforms events into states. This module contains functions which
;; transform a sequence of events into a list of states.
;; 
;; Percentiles: yields the 50th, 95th, 99th, 100th percentile event from the
;;              stream.
;; Sum:         yields the sum of all events in the sequence.
;; Mean:        yields the mean of all events in the sequence.
;; Rate:        sums the events and divides by time.

(defn sorted-sample [s & points]
  (if (empty? s) 
    '()
    (let [sorted (sort-by :metric s)
          n (count sorted)
          extract (fn [point]
                    (let [idx (min (- n 1) (int (Math/floor (* n point))))]
                      (nth sorted idx)))]
      (map extract points))))

(defn mean [s]
  (if (empty? s)
    '()
    (let [sum (reduce + (map :metric s))
          mean (/ sum (count s))
          state (first s)]
      '((assoc state :metric mean)))))
