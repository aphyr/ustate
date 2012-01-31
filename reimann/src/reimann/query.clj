(ns reimann.query
  (:import (org.antlr.runtime ANTLRStringStream
                              CommonTokenStream)
           (reimann QueryLexer QueryParser)))

; With many thanks to Brian Carper
; http://briancarper.net/blog/554/antlr-via-clojure

(defn parse-string [s]
  "Parse nodes for a string containing an expression"
    (let [lexer (QueryLexer. (ANTLRStringStream. s))
                  tokens (CommonTokenStream. lexer)
                  parser (QueryParser. tokens)]
          (.getTree (.expr parser))))

(defn node-ast [node]
  "The AST for a given parse node"
  (let [n    (.getText node)
        kids (remove (fn [x] (= x :useless)) 
                     (map node-ast (.getChildren node)))]
    (case n
      "or"  (apply list 'or kids)
      "and" (apply list 'and kids)
      "not" (apply list 'not kids)
      "="   (apply list '= kids)
      ">"   (apply list '> kids)
      ">="  (apply list '>= kids)
      "<"   (apply list '< kids)
      "<="  (apply list '<= kids)
      "=~"  (apply list 'approx kids)
;      "=~" (apply list 're-find
;                  (re-pattern (.replaceAll n "%" ".*"))
;                  kids)
      "!="  (list 'not (apply list '= kids))
      "("           :useless
      ")"           :useless
      "nil"         nil
      "null"        nil
      "true"        true
      "false"       false
      "host"        'host
      "service"     'service
      "state"       'state
      "description" 'description
      "metric_f"    'metric_f
      "time"        'time
      (when n (read-string n)))))

(defn approx [value pattern]
  "Approximately matches value with pattern."
  (re-find (re-pattern (.replaceAll pattern "%" ".*")) value))

(defn ast [string]
  "The expression AST for a given string"
  (let [node (parse-string string)]
    (node-ast node)))

(defn fun [ast]
  "Transforms an AST into a fn [event] which returns true if the query matches
  that event."
  (eval
    (list 'fn ['event]
      (list 'let '[host        (:host event)
                   service     (:service event)
                   state       (:state event)
                   description (:description event)
                   metric_f    (:metric_f event)
                   time        (:time event)]
        ast))))
