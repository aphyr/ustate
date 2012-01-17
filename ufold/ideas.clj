; This is a ufold config file (or rather, what it *will* look like)
;
; Each event is applied to these streams. An event is a struct like
;  :service "cpu"
;  :host "foo.com"
;  :time 123456789
;  :metric_f 0.12
;  :description "0.12 of 8 cores user/sys/io_wait"
;  :state "ok"
;
; Each stream is a function which, when called with an event, transforms the
; event in some way and invokes its children.
;
; The index is a stateful table of the most recent event for any given [host,
; service] pair; it reflects the most recent information about the system.
(let [index (hsql-index)
      streams
  [
   ; Sum all the events we get for 'visits' from any host and find a rate of
   ; visits/sec over each 10-second window. Reset the host of the resulting
   ; rate event to nil. With that rate, index it and also update graphite.
   (where :service "visits"
          (rate 10
                (set host nil
                     index
                     graphite))
          
          ; Also index the rate of visits on a per-host basis
          (by :host (rate 10 index)))

   
   ; CPU, memory, and disk for all hosts
   (where :service #"^(cpu|memory|disk)"
          ; Index (keep a copy of the most recent event) all these services
          index

          ; For each distinct service, find the average and graph that too.
          ; Produces a CPU average, memory average, "disk a" average, "disk b"
          ; average, etc.
          (by :service
                (mean 
                  (set host nil 
                       graphite))))

   ; Aggregate response times and generate 50th, 95th, 99th, 100th percentiles
   ; over each 60 second interval.
   (where :service #"response time"
          (percentiles 60 [0.5 0.95 0.99 1] index))

   ; Produce a daily email with the total number of signups
   (where :service "signups" (sum (* 24 3600) (email "ceo@startup.foo" )))
]])

; Listen for protobuf-encoded events over TCP and UDP, forward all events to
; streams.
(tcp-server :port 1234 streams)
(udp-server streams)
