(ns ufold.test.client
  (:use [ufold.common])
  (:use [ufold.core])
  (:use [ufold.server])
  (:use [ufold.client])
  (:use [clojure.test]))

(deftest reconnect
  (let [server (tcp-server (core))
        client (tcp-client)]
    (try
      ; Initial connection works
      (is (send-event client {:service "test"}))

      ; Kill server; should fail.
      (server)
      (is false? (send-event client {:service "test"}))

      
      (let [server (tcp-server (core))]
        (try
          (send-event client {:service "test"})
          (finally
            (server))))

      (finally
        (close-client client)
        (server)))))
