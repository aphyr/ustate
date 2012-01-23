(ns reimann.common
  (:use [protobuf])
  (:import [java.util Date])
  (:use [clojure.contrib.math]))

(defprotobuf Msg Reimann$Msg)
(defprotobuf State Reimann$State)
(defprotobuf Event Reimann$Event)

(defmacro threaded [thread-count & body]
  `(let [futures# (map (fn [_#] (future ~@body))
                      (range 0 ~thread-count))]
    (doseq [fut# futures#] (deref fut#))))

(defn ppmap [threads f s]
  (let [work (partition (/ (count s) threads) s)
        result (pmap (fn [part] (doall (map f part))) work)]
    (doall (apply concat result))))

(defn unix-time []
  (/ (System/currentTimeMillis) 1000))

; Create a new event
(defn event [opts]
  (let [t (round (or (opts :time)
                     (unix-time)))]
    (apply protobuf Event
      (apply concat (merge opts {:time t})))))

(defn approx-equal 
([x,y]
  (approx-equal x y 0.01))
([x, y, tol]
  (if (= x y) true
    (let [f (try (/ x y) (catch java.lang.ArithmeticException e (/ y x)))]
      (< (- 1 tol) f (+ 1 tol))))))

; Create a new state
(defn state [opts]
  (let [t (round (or (opts :time)
                     (unix-time)))]
    (apply protobuf State
      (apply concat (merge opts {:time t})))))
