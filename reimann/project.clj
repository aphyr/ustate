(defproject reimann "0.0.1-SNAPSHOT"
  :description "reimann: folds events into states"
  :dependencies [
    [clojure "1.2.0"]
    [aleph "0.2.0"]
    [protobuf "0.6.0-beta4"]
    [org.antlr/antlr "3.2"]
  ]
  :dev-dependencies [
    [protobuf "0.6.0-beta4"]
  ]
  :java-source-path "src/reimann/"
  :aot [reimann.bin]
  :main reimann.bin
  :disable-implicit-clean true
)
