(ns reimann.server
  (:use [reimann.core])
  (:use [reimann.common])
  (:use clojure.contrib.logging)
  (:use lamina.core)
  (:use aleph.tcp)
  (:use gloss.core)
  (:use protobuf)
  (:require gloss.io))

(defn decode [s]
  (let [buffer (gloss.io/contiguous s)]
    (let [bytes (byte-array (.remaining buffer))]
      (.get buffer bytes 0 (alength bytes))
      (protobuf-load Msg bytes))))

; maybe later
;(defn udp-server []
;  (let [channel (wait-for-result (udp-socket {:port 5555}))]   

; Returns a handler that applies messages to the given streams (by reference)
(defn handler [core]
  (fn [channel client-info]
    (receive-all channel (fn [buffer]
      (when buffer
        ; channel isn't closed; this is our message
        (try
          (let [msg (decode buffer)]
            ; Send each event to each stream
            (doseq [event (msg :events)
                    stream (deref (:streams core))]
              (stream event))

            ; And acknowledge
            (enqueue channel (protobuf-dump
              (protobuf Msg :ok true))))
          (catch java.nio.channels.ClosedChannelException e
            (log :warn (str "channel closed")))
          (catch com.google.protobuf.InvalidProtocolBufferException e
            (log :warn (str "invalid message, closing " client-info))
            (close channel))
          (catch Exception e
            (log :warn (str "Exception " e))
            (close channel))))))))

(defn tcp-server
  ([core]
    (tcp-server core {}))
  ([core opts]
  (let [handler (handler core)]
    (start-tcp-server handler 
      (merge {
        :port 5555
        :frame (finite-block :int32)
      } opts)))))
