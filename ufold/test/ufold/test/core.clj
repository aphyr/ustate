(ns ufold.test.core
  (:require [ufold.server])
  (:require [ufold.sinks])
  (:require [ufold.streams])
  (:use [ufold.client])
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [clojure.contrib.generic.functor :only (fmap)])
  (:use [clojure.test]))

(comment
(defmacro tim
  "Evaluates expr and returns the time it took in seconds"
  [expr]
  `(let [start# (. System (nanoTime))
         ret# ~expr]
     (/ (- (. System (nanoTime)) start#) 1000000000.0)))

(defn approx-equal [x, y]
  (if (= x y) true
    (let [f (try (/ x y) (catch java.lang.ArithmeticException e (/ y x)))]
      (< 0.99 f 1.01))))

(deftest sum
         (let [core (core)
               server (ufold.server/tcp-server core)
               stream (ufold.streams/sum {:host "host"
                                          :service "service"
                                          :description "desc"})
               sink (ufold.sinks/list-sink)
               client (ufold.client/tcp-client)]
           (try
             (dosync
               (alter (core :servers) conj server)
               (alter (core :streams) conj stream)
               (alter (core :sinks) conj sink))

             ; Send some events over the network
             (send-event client {:metric_f 1})
             (send-event client {:metric_f 2})
             (close-client client)
             
             ; Flush
             (flush-stream-sink stream sink)

             ; Confirm receipt
             (let [state (first (deref (sink :value)))]
               (is (= 3 (state :metric_f)))
               (is (> (state :time) 1326494648))
               (is (= "host" (state :host)))
               (is (= "service" (state :service)))
               (is (= "desc" (state :description))))

             (finally
               (close-client client)
               (stop core)))))

(deftest rate
         (let [core (core)
               server (ufold.server/tcp-server core)
               stream (ufold.streams/rate {:host "host"
                                           :service "service"
                                           :description "desc"})
               sink (ufold.sinks/list-sink)
               client (ufold.client/tcp-client)]
           (try
             (dosync
               (alter (core :servers) conj server)
               (alter (core :streams) conj stream)
               (alter (core :sinks) conj sink))

             (let [t (tim (do
                       ; Reset sink
                       (flush-stream-sink stream sink)

                       ; Send some events over the network
                       (send-event client {:metric_f 1})
                       (Thread/sleep 100)
                       (send-event client {:metric_f 2})
                       (Thread/sleep 100)
                       (close-client client)
                       
                       ; Flush
                       (flush-stream-sink stream sink)))]

               ; Confirm receipt
               (let [state (first (deref (sink :value)))]
                 (is (approx-equal (/ 3.0 t) (state :metric_f)))
                 (is (approx-equal (state :time) (unix-time)))
                 (is (= "host" (state :host)))
                 (is (= "service" (state :service)))
                 (is (= "desc" (state :description)))))

             (finally
               (close-client client)
               (stop core)))))

(deftest percentiles
         (let [core (core)
               server (ufold.server/tcp-server core)
               stream (ufold.streams/percentiles)
               sink (ufold.sinks/list-sink)
               client (ufold.client/tcp-client)]
           (try
             (dosync
               (alter (core :servers) conj server)
               (alter (core :streams) conj stream)
               (alter (core :sinks) conj sink))

             ; Send some events over the network
             (doseq [n (shuffle (take 101 (iterate inc 0)))]
               (send-event client {:metric_f n :service "per"}))
             (close-client client)
             
             ; Flush
             (flush-stream-sink stream sink)

             ; Get states
             (let [states (fmap first (group-by :service (deref (sink :value))))]
               (is (= ((states "per 0.5") :metric_f) 50))
               (is (= ((states "per 0.95") :metric_f) 95))
               (is (= ((states "per 0.99") :metric_f) 99))
               (is (= ((states "per 1") :metric_f) 100)))

             (finally
               (close-client client)
               (stop core))))))
