(ns ufold.test.server
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [ufold.server])
  (:use [clojure.test])
  (:use [protobuf])
  (:use [lamina.core])
  (:use [aleph.tcp])

(deftest ignores-garbage
  (let [server (tcp-server (core))
        client (tcp-client :host "localhost" :port 5000)]
    (try
      (eclient 
               (java.nio.ByteBuffer/wrap (byte-array (map byte [0 1 2]))))
      (is nil? (wait-for-message client))
      (is (closed? client))
      (finally
        (close client)
        (server)))))
