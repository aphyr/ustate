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

(deftest where-test
         (let [r (ref nil)
               s (where :service "foo" (fn [e] (dosync (ref-set r e))))]
           (s {:service "bar"})
           (is (= nil (deref r)))

           (s {:service "foo"})
           (is (= {:service "foo"} (deref r)))))

(deftest with-test-test ; goddamnit fucking namespace collision bullshit
         (let [r (ref nil)
               s (with :service "foo" (fn [e] (dosync (ref-set r e))))]
           (s {:service nil})
           (is (= {:service "foo"} (deref r)))

           (s {:service "foo"})
           (is (= {:service "foo"} (deref r)))

           (s {:service "bar" :test "baz"})
           (is (= {:service "foo" :test "baz"} (deref r)))))

(deftest by-test
         ; Each test stream keeps track of the first host it sees, and confirms
         ; that each subsequent event matches that host.
         (let [i (ref 0)
               s (by :host
                     (let [host (ref nil)]
                       (fn [event]
                         (dosync
                           (alter i inc)
                           (when (nil? (deref host))
                             (ref-set host (event :host)))
                           (is (= (deref host) (event :host)))))))
               events (map (fn [h] {:host h}) [:a :a :b :a :c :b])]
           (doseq [event events]
             (s event))
           (is (= (count events) (deref i)))))
