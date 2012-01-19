(ns ufold.test.server
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [ufold.server])
  (:use [ufold.client])
  (:use [clojure.test])
  (:use [protobuf])
  (:use [lamina.core]))

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
