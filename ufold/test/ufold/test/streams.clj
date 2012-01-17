(ns ufold.test.streams
  (:use [ufold.streams])
  (:use [clojure.test]))

(deftest create-stream
         ; Default
         (let [s (stream {})]
           (is (true? ((s :pred) {:x :foo})))
           (is (= (s :type) :immediate))
           (is (= (s :init) '()))
           (is (= (s :in) identity))
           (is (= (s :fold) conj))
           (is (= (s :out) identity))
           (is (= (deref (s :state)) '())))

        ; Custom initial state
        (let [s (stream {:init 2})]
          (is (= (deref (s :state)) 2))))

(deftest stream-immediate
         (let [s (stream {
                             :type :immediate
                             :init 0
                             :in :x
                             :fold +
                             :out (fn [x] {:x x})})
               events (take 100 (repeatedly (fn [] {:x (rand-int 1000)})))
               sum (reduce + (map :x events))]
           (doseq [e events] (apply-stream s e))
           (is (= {:x sum} (flush-stream s)))))

(deftest stream-bulk
         (let [s (stream {
                             :type :bulk
                             :in :x
                             :fold (fn [bits] (reduce + bits))
                             :out (fn [x] {:x x})})
               events (take 100 (repeatedly (fn [] {:x (rand-int 1000)})))
               sum (reduce + (map :x events))]
           (doseq [e events] (apply-stream s e))
           (is (= {:x sum} (flush-stream s)))))

(deftest where
         (let [r (ref nil)
               s (where [:service "foo"] #(ref-set r %))]
           (s {:service "bar"})
           (is (= nil (deref r)))

           (s {:service "foo"})
           (is (= {:service "foo"} (deref r)))))
