(defproject reimann "0.0.1-SNAPSHOT"
  :description "reimann: folds events into states"
  :repositories {
    "boundary-site" "http://maven.boundary.com/artifactory/repo"
  }
  :dependencies [
    [clojure "1.2.0"]
    [aleph "0.2.0"]
    [protobuf "0.6.0-beta4"]
    [org.antlr/antlr "3.2"]
    [com.boundary/high-scale-lib "1.0.3"]
    [clj-time "0.3.4"]
    [com.draines/postal "1.7-SNAPSHOT"]
  ]
  :dev-dependencies [
    [protobuf "0.6.0-beta4"]
  ]
  :test-selectors {:default (complement :integration)
                   :integration :integration
                   :all (fn [_] true)}
  :java-source-path "src/reimann/"
  :aot [reimann.bin]
  :main reimann.bin
  :disable-implicit-clean true
)
