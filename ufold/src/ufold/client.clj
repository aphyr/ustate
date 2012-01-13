(ns ufold.client
  (:require [aleph.tcp])
  (:use [ufold.common])
  (:use [lamina.core])
  (:use [protobuf])
  (:use [gloss.core]))

; Transform a message into bytes
(defn encode [message]
  (protobuf-dump message))

; Send a message over the given client
(defn send-message [client, message]
  (enqueue client (encode message)))

; Send an event Protobuf
(defn send-event-protobuf [client event]
  (send-message client
    (protobuf Msg :events [event])))

; Send an event (any map; will be passed to (event)) over the given client
(defn send-event [client eventmap]
  (send-event-protobuf client (event eventmap)))

; Send states over the given client.
(defn send-states [client states]
  (send-message client
    (protobuf Msg :states states)))

; Open a new TCP client
(defn tcp-client [& { :keys [host port]
                      :or {port 5555
                           host "localhost"}
                      :as opts}]
  (wait-for-result
    (aleph.tcp/tcp-client {:host host
                           :port port
                           :frame (finite-block :int32)})))

; Close a client
(defn close-client [client]
  (lamina.core/close client))
