(ns ufold.test.core
  (:use [ufold.core])
  (:use [clojure.test]))

(use 'lamina.core 'aleph.tcp 'gloss.core)

(deftest starts
  (let [server (start-server)]
    (server)
  ))

(deftest echoes
  (let [server (start-server)]
    (let [client (start-client)]
      (try
        (enqueue client "hello")
        (is (= "hello" (wait-for-message client)))
      (finally
        (close client)
        (server))))))
