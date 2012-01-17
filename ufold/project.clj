(defproject ufold "0.0.1-SNAPSHOT"
  :description "ufold: folds events into states"
  :dependencies [
    [clojure "1.3.0"]
    [aleph "0.2.0"]
    [clojure-protobuf "0.4.5"]
  ]
  :dev-dependencies [
    [criterium "0.2.0"]
  ]
  :cake-plugins [
    [cake-protobuf "0.5.0-beta1"]
  ]
  :aot [ufold.bin]
  :main ufold.bin
)
