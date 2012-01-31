(ns reimann.test.query
  (:use [reimann.query])
  (:use [clojure.test]))

(deftest ast-test
         (are [s expr] (= (ast s) expr)
              ; Fields
              "state = true"        '(= state true)
              "host = true"         '(= host true)
              "service = true"      '(= service true)
              "description = true"  '(= description true)
              "metric_f = true"     '(= metric_f true)
              "time = true"         '(= time true)

              ; Literals
              "state = true"  '(= state true)
              "state = false" '(= state false)
              "state = nil"   '(= state nil)
              "state = null"  '(= state nil)

              ; Integers
              "state = 0"  '(= state 0)
              "state = 1"  '(= state 1)
              "state = -1" '(= state -1)
              
              ; Floats
              "state = 1."     '(= state 1.)
              "state = 0.0"    '(= state 0.0)
              "state = 1.5"    '(= state 1.5)
              "state = -1.5"   '(= state -1.5)
              "state = 1e5"    '(= state 1e5)
              "state = 1E5"    '(= state 1e5)
              "state = -1.2e-5" '(= state -1.2e-5)

              ; Strings
              "state = \"\""                '(= state "")
              "state = \"foo\""             '(= state "foo")
              "state = \"\\b\\t\\n\\f\\r\"" '(= state "\b\t\n\f\r")
              "state = \" \\\" \\\\ \""     '(= state " \" \\ ")
              "state = \"辻斬\""            '(= state "辻斬")

              ; Simple predicates
              "state = 2"                   '(= state 2)
              "state > 2"                   '(> state 2)
              "state < 2"                   '(< state 2)
              "state >= 2"                  '(>= state 2)
              "state <= 2"                  '(<= state 2)
              "state != 2"                  '(not (= state 2))
              "state =~ \"%foo%\""          '(approx state "%foo%")

              ; Boolean operators
              "not host = 1"                '(not (= host 1))
              "host = 1 and state = 2"      '(and (= host 1) (= state 2))
              "host = 1 or state = 2"       '(or (= host 1) (= state 2))
              
              ; Grouping
              "(host = 1)"                  '(= host 1)
              "((host = 1))"                '(= host 1)

              ; Precedence
              "not host = 1 and host = 2"
              '(and (not (= host 1)) (= host 2))

              "not host = 1 or host = 2 and host = 3"
              '(or (not (= host 1))
                   (and (= host 2) (= host 3)))

              "not ((host = 1 or host = 2) and host = 3)"
              '(not (and (or (= host 1)
                             (= host 2))
                         (= host 3)))
              ))

;(prn (ast "state = 2 or (state = 3 or state != 4)"))
;(prn ((fun (ast "state = 2")) {:state 2}))
;(prn ((fun (ast "state = 2")) {:state 2}))
