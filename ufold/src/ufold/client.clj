(ns ufold.client
  (:require [aleph.tcp])
  (:use [lamina.core])
  (:use [protobuf])
  (:use [gloss.core]))

; Transform a message into bytes
(defn encode [message]
  (protobuf-dump message))

; Send a message over the given client
(defn send-message [client, message]
  (enqueue client (encode message)))

; Send states over the given client.
(defn send-states [client states]
  (send-message client
    (protobuf ufold.core/Msg :states states)))

; Open a new TCP client
(defn tcp-client [& { :keys [host port]
                      :or {port 5555
                           host "localhost"}
                      :as opts}]
  (wait-for-result
    (aleph.tcp/tcp-client {:host host
                           :port port
                           :frame (finite-block :int32)})))
