(ns reimann.test.query
  (:use [reimann.query])
  (:use [clojure.test]))

(deftest ast-field
         (is (= (ast "metric_f")
                '')))

