(defproject reimann "0.0.1-SNAPSHOT"
  :description "reimann: folds events into states"
  :dependencies [
    [clojure "1.2.0"]
    [aleph "0.2.0"]
    [protobuf "0.6.0-beta4"]
  ]
  :dev-dependencies [
    [protobuf "0.6.0-beta4"]
  ]
  :cake-plugins [
    [cake-protobuf "0.5.0-beta1"]
  ]
  :aot [reimann.bin]
  :main reimann.bin
  :disable-implicit-clean true
)
