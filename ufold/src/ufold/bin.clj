(ns ufold.bin
  (:require ufold.config)
  (:gen-class))

(defn -main [& argv]
  (ufold.config/include (first argv)))
