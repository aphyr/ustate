(ns ufold.test.core
  (:require [ufold.server])
  (:require [ufold.sinks])
  (:require [ufold.streams])
  (:use [ufold.client])
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [clojure.test]))

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
