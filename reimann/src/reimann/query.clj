(ns reimann.query
  (:use [net.cgrand.parsley :as p]))

(def parser
  (
  

  (defn ast [string]
  "Returns the query AST for a given string."
  (grammar (wrap-string string)))
