(ns ufold.server
  (:use [ufold.streams :only (apply-streams)])
  (:use [ufold.core])
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
(defn handler [streams]
  (fn [channel client-info]
    (receive-all channel (fn [buffer]
      (when buffer
        ; channel isn't closed; this is our message
        (try
          (let [msg (decode buffer)]
            ; Send each event to each stream
            (doseq [event (msg :events)]
              (apply-streams (deref streams) event))
            ; And acknowledge
            (enqueue channel (protobuf-dump
              (protobuf Msg :ok true))))
          (catch com.google.protobuf.InvalidProtocolBufferException e
            (log :warn (str "invalid message, closing " client-info))
            (close channel))))))))

(defn tcp-server [& { :keys [streams port]
                      :or {streams (ref [])
                           port 5555} }]
  (let [handler (handler streams)]
    (start-tcp-server handler
                      {:port port,
                       :frame (finite-block :int32)})))
