(ns ufold.server
  (:use clojure.contrib.logging)
  (:use lamina.core)
  (:use aleph.tcp)
  (:use gloss.core)
  (:use protobuf)
  (:require gloss.io))

(defprotobuf Msg Ufold$Msg)

;; Server
(defn dump-bytes [bytes]
  (log :info ["Bytes are " (seq bytes)]))

(defn decode [s]
  (let [buffer (gloss.io/contiguous s)]
    (let [bytes (byte-array (.remaining buffer))]
      (.get buffer bytes 0 (alength bytes))
      (protobuf-load Msg bytes))))

(defn encode [message]
  (protobuf-dump message))

(defn echo-handler [channel client-info]
  (receive-all channel (fn [buffer]
    (when buffer
      ; Channel isn't closed; this is our message.
      (try
        (let [msg (decode buffer)]
          (enqueue channel (encode msg)))
        (catch com.google.protobuf.InvalidProtocolBufferException e
          (log :warn (str "invalid message; closing " client-info))
          (close channel)))))))

(defn tcp-server []
  (start-tcp-server echo-handler
                    {:port 5555,
                     :frame (finite-block :int32)}))
