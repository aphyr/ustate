(ns ufold.client
  (:require [aleph.tcp])
  (:use [lamina.core])
  (:use [gloss.core]))

(defn tcp-client [& { :keys [host port]
                      :or {port 5555
                           host "localhost"}
                      :as opts}]
  (wait-for-result
    (aleph.tcp/tcp-client {:host host
                           :port port
                           :frame (finite-block :int32)})))
