# A real-world configuration file.

emailer.from = 'ustate@showyou.com'
emailer.tell 'aphyr@aphyr.com', 'state != "ok"'
emailer.tell 'you@foo.com', 'service =~ "importer %"'

a = aggregator

# Thumbnailer
a.sum 'service =~ "tablet thumbnailer %"', service: 'tablet thumbnailer'

# Feed merger
a.sum 'service = "tablet feed merger" and host != null', service: 'tablet feed merger'

# API
a.sum 'service =~ "api % rate" and host != null and metric_f != null', service: 'api rate'
a.average 'service =~ "api % 50" and host != null and metric_f != null', service: 'api 50'
a.average 'service =~ "api % 95" and host != null and metric_f != null', service: 'api 95'
a.average 'service =~ "api % 99" and host != null and metric_f != null', service: 'api 99'

# Importer
a.sum 'service =~ "importer twitter rate" and host != null'
graphite.graph 'service = "importer twitter rate" and host = null'

# Riak cluster
a.sum 'service = "riak node_gets" and host != null'
a.sum 'service = "riak node_puts" and host != null'
a.sum 'service = "riak keys and host != null"'
a.average 'service == "riak get 50" and host != null'
a.average 'service == "riak get 95" and host != null'
a.average 'service == "riak get 99" and host != null'
a.average 'service == "riak put 50" and host != null'
a.average 'service == "riak put 95" and host != null'
a.average 'service == "riak put 99" and host != null'

# Reaper
a.sum 'service = "reaper deletes" and host != null'
graphite.graph 'service =~ "reaper %" and host = null'

# Tablet
graphite.graph 'service = "videos total"'
graphite.graph 'service = "users total"'
graphite.graph 'service = "users active"'

# Health
graphite.graph 'service = "cpu" or service =~ "disk %" or service = "load" or service = "memory"'

# Videos
graphite.graph 'service = "videos total"'

# Users
graphite.graph 'service = "users total"'
graphite.graph 'service = "users active"'

# Riak
graphite.graph 'service =~ "riak get %" or service =~ "riak put %" or service = "riak node_gets" or service = "riak node_puts" or service = "riak read_repairs" or service = "riak disk" or service = "riak keys"'

# Queues
graphite.graph 'service =~ "queue %"'

# Ustate
graphite.graph 'service =~ "ustate %"'

# Queues
graphite.graph 'service =~ "queue %"'

# API
graphite.graph 'service = "api rate"'
graphite.graph 'service = "api 50"'
graphite.graph 'service = "api 95"'
graphite.graph 'service = "api 99"'

# Various other services
graphite.graph 'service = "tablet thumbnailer"'
graphite.graph 'service =~ "redis %"'
graphite.graph 'service = "tablet feed merger" and host = null'
