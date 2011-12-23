(ns ufold.test.bench
  (:use [ufold.core])
  (:use [ufold.server])
  (:use [ufold.client])
  (:use [ufold.streams])
  (:use [clojure.test])
  (:use [protobuf])
  (:use [lamina.core]))

(deftest trecord
         (let [stream (defstream {:type :immediate
                           :in :metric_f
                           :out (fn [xs] (map 
                                  (fn [x] (protobuf State :metric_f x ))
                                  xs))})
        streams (ref [stream])
        server (tcp-server :streams streams)
        client (tcp-client)
        n 1000
        events (take n (repeatedly (fn [] 
                 (protobuf State :metric_f (rand)))))]
    (try
      (time (do
        ; Send all events to server
        (doseq [e events]
          (send-message client (protobuf Msg :events [e])))
        ; Read confirmations
        (dotimes [i n] (wait-for-message client))))
      
    (finally
      (close client)
      (server)))))
