(ns ufold.test.core
  (:use [ufold.core])
  (:use [ufold.client])
  (:use [clojure.test])
  (:use [protobuf])
  (:use [lamina.core]))

(deftest echoes
  (let [server (start-server)
        client (tcp-client)
        message (protobuf Msg :foo "hello")]
    (try
      (enqueue client (encode message))
      (is (= message (decode (wait-for-message client))))
    (finally
      (close client)
      (server)))))

(deftest ignores-garbage
  (let [server (start-server)
        client (tcp-client)]
    (try
      (enqueue client (java.nio.ByteBuffer/wrap (byte-array (map byte [0 1 2]))))
      (is nil? (wait-for-message client))
      (is (closed? client))
      (finally
        (close client)
        (server)))))
