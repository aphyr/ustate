(ns ufold.test.folds
  (:use [ufold.folds])
  (:use [clojure.test]))

(def random-metrics (map (fn [x] {:metric x}) (repeatedly rand)))

(deftest sorted-sample-empty
         (is (= () (sorted-sample '())))
         (is (= () (sorted-sample '() 0)))
         (is (= () (sorted-sample '() 0.5)))
         (is (= () (sorted-sample '() 1.0)))
         (is (= () (sorted-sample '() 0 0.5 1.0))))

(deftest sorted-sample-single
         (let [s {:metric 1}]
           (is (= '(s,s,s) (sorted-sample '(s) 0.0 0.5 1.0)))))

(deftest sorted-sample-rand
         (let [small (take 100 (filter #(< (% :metric) 0.5) random-metrics))
               big   (take 100 (filter #(> (% :metric) 0.5) random-metrics))
               r (concat big '({:metric 0.5} {:metric -1} {:metric 2}) small)]
           (is (= '(-1 0.5 2) (map :metric (sorted-sample r 0 0.5 1))))))
