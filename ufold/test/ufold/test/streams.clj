(ns ufold.test.streams
  (:use [ufold.streams])
  (:use [clojure.test]))

(deftest create-stream
         ; Default
         (let [s (defstream {})]
           (is (true? ((s :pred) {:x :foo})))
           (is (= (s :type) :immediate))
           (is (= (s :init) '()))
           (is (= (s :in) identity))
           (is (= (s :fold) conj))
           (is (= (s :out) identity))
           (is (= (deref (s :state)) '())))

        ; Custom initial state
        (let [s (defstream {:init 2})]
          (is (= (deref (s :state)) 2))))

(deftest stream-immediate
         (let [s (defstream {
                             :type :immediate
                             :init 0
                             :in :x
                             :fold +
                             :out (fn [x] {:x x})})
               events (take 100 (map (fn [x] {:x x}) (repeatedly rand)))
               sum (reduce + (map :x events))]
           (doseq [e events] (apply-stream s e))
           (is (= {:x sum} (flush-stream s)))))

(deftest stream-bulk
         (let [s (defstream {
                             :type :bulk
                             :in :x
                             :fold (fn [bits] (reduce + bits))
                             :out (fn [x] {:x x})})
               events (take 100 (map (fn [x] {:x x}) (repeatedly rand)))
               sum (reduce + (map :x events))]
           (doseq [e events] (apply-stream s e))
           (is (= {:x sum} (flush-stream s)))))
