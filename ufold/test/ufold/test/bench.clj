(ns ufold.test.bench
  (:use [ufold.core])
  (:use [ufold.common])
  (:use [ufold.server])
  (:use [ufold.client :only [tcp-client close-client send-event-protobuf]])
  (:use [ufold.streams])
  (:use [clojure.test]))

(deftest sum-test
         (let [final (ref nil)
               core (core)
               server (tcp-server core)
               stream (sum (register final))
               n 1000
               threads 10
               events (take n (repeatedly (fn [] 
                        (event {:metric_f 1}))))]

           (dosync
             (alter (core :servers) conj server)
             (alter (core :streams) conj stream))

           (doall events)

           (try 
             (time (threaded threads
                             (let [client (tcp-client)]
                                (doseq [e events]
                                  ; Send all events to server
                                  (send-event-protobuf client e))
                               (close-client client))))
             
            (is (= (* threads n) (:metric_f (deref final)))) 

            (finally
              (stop core)))))
