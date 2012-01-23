(ns ufold.test.server
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [ufold.server])
  (:use [clojure.test])
  (:use [protobuf])
  (:use [lamina.core])
  (:use [aleph.tcp])
  (:use [gloss.core]))

(deftest ignores-garbage
  (let [server (tcp-server (core))
        client (wait-for-result 
                 (aleph.tcp/tcp-client {:host "localhost" 
                                        :port 5555
                                        :frame (finite-block :int32)}))]
    (try
      (enqueue client 
               (java.nio.ByteBuffer/wrap (byte-array (map byte [0 1 2]))))
      (is nil? (wait-for-message client))
      (is (closed? client))
      (finally
        (close client)
        (server)))))
