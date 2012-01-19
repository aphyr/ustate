(ns ufold.test.core
  (:require [ufold.server])
  (:require [ufold.sinks])
  (:require [ufold.streams])
  (:use [ufold.client])
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [clojure.contrib.generic.functor :only (fmap)])
  (:use [clojure.test]))

(defmacro tim
  "Evaluates expr and returns the time it took in seconds"
  [expr]
  `(let [start# (. System (nanoTime))
         ret# ~expr]
     (/ (- (. System (nanoTime)) start#) 1000000000.0)))

(deftest sum
         (let [core (core)
               done (ref [])
               server (ufold.server/tcp-server core)
               stream (ufold.streams/sum (ufold.streams/append done)) 
               client (ufold.client/tcp-client)]
           (try
             (dosync
               (alter (core :servers) conj server)
               (alter (core :streams) conj stream))

             ; Send some events over the network
             (send-event client {:metric_f 1})
             (send-event client {:metric_f 2})
             (send-event client {:metric_f 3})
             (close-client client)
             
             ; Confirm receipt
             (let [l (deref done)]
               (is (= [1 3 6] 
                      (map (fn [x] (:metric_f x)) l))))

             (finally
               (close-client client)
               (stop core)))))

(deftest percentiles
         (let [core (core)
               out (ref [])
               server (ufold.server/tcp-server core)
               stream (ufold.streams/percentiles 1 [0 0.5 0.95 0.99 1] 
                                                 (ufold.streams/append out))
               client (ufold.client/tcp-client)]
           (try
             (dosync
               (alter (core :servers) conj server)
               (alter (core :streams) conj stream))

             ; Wait until we aren't aligned... ugh, timing
             ;(Thread/sleep (- 1100 (* (mod (unix-time) 1) 1000)))

             ; Send some events over the network
             (doseq [n (shuffle (take 101 (iterate inc 0)))]
               (send-event client {:metric_f n :service "per"}))
             (close-client client)
             
             ; Wait for percentiles
             (Thread/sleep 1000)

             ; Get states
             (let [events (deref out)
                   states (fmap first (group-by :service events))]

               (is (= ((states "per 0.5") :metric_f) 50))
               (is (= ((states "per 0.95") :metric_f) 95))
               (is (= ((states "per 0.99") :metric_f) 99))
               (is (= ((states "per 1") :metric_f) 100)))

             (finally
               (close-client client)
               (stop core)))))
