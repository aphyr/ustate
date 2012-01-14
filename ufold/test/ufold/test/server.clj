(ns ufold.test.server
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [ufold.server])
  (:use [ufold.client])
  (:use [ufold.streams])
  (:use [clojure.test])
  (:use [protobuf])
  (:use [lamina.core]))

(deftest record
  (let [stream (stream {:type :immediate
                           :in :metric_f
                           :out (fn [xs] (map 
                                  (fn [x] (protobuf State :metric_f x ))
                                  xs))})
        streams (ref [stream])
        server (tcp-server {:streams streams})
        client (tcp-client)
        events (take 1 (repeatedly (fn [] 
                 (protobuf State :metric_f (rand)))))]
    (try
      ; Send all events to server
      (doseq [e events]
        (send-message client (protobuf Msg :events [e])))
      ; Verify that events are present
      (let [recorded-events (flush-stream stream)]
        (is (= events recorded-events)))
    (finally
      (close client)
      (server)))))

(deftest ignores-garbage
  (let [server (tcp-server (core))
        client (tcp-client)]
    (try
      (enqueue client (java.nio.ByteBuffer/wrap (byte-array (map byte [0 1 2]))))
      (is nil? (wait-for-message client))
      (is (closed? client))
      (finally
        (close client)
        (server)))))
