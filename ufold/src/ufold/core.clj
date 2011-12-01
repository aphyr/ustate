(ns ufold.core)

(use 'lamina.core 'aleph.tcp `gloss.core)

(defn echo-handler [channel client-info]
  (receive-all channel (fn [buffer]prn "message: " %))
  (siphon channel channel))

(defn start-server []
  (start-tcp-server echo-handler
                    {:port 5555,
                     :frame (finite-block :int32)}))

(defn encode [message]

  )

(defn send-client [client message]
   

(defn start-client []
  (wait-for-result
    (tcp-client {
                 :host "localhost",
                 :port 5555,
                 :frame (finite-block :int32)})))
