Overview
======

UState ("United States", "microstate", etc.) is a state aggregation daemon. It
accepts a stream of state transitions and maintains an index of service states,
which can be queried or forwarded to various handlers. A state is simply:

    state {
      host: A hostname, e.g. "api1", "foo.com",
      service: e.g. "API port 8000 reqs/sec",
      state: Any string less than 255 bytes, e.g. "ok", "warning", "critical",
      time: The time that the service entered this state, in unix time,
      description: Freeform text,
      metric_f: A floating-point number associated with this state, e.g. the number of reqs/sec,
      once: A boolean, described below.
    }

Normally, every state received by the server fires Index#on_state. When
state.state changes, Index#on_state_change is called. You can, for example,
register to send a single email whenever a state changes to :warning.

:once states are transient. They fire Index#on_state and #on_state_once, but do
*not* update the index. They can be used for events which are instantaneous;
instead of sending {state: error} and {state: ok}, send {state: error,
once:true}. 

For example, recoverable errors may not hang your application, but
should be processed by the email notifier. Sending a :once state with
the error description means you can receive an email for each error,
instead of two for entering and exiting the error state.

At http://showyou.com, we use UState to monitor the health and performance of
hundreds of services across our infrastructure, including CPU, queries/second,
latency bounds, disk usage, queues, and others.

UState also includes a simple dashboard Sinatra app.

Installing
==========

    git clone git://github.com/aphyr/ustate.git

or

    gem install ustate-client

For the client:

    gem install beefcake trollop

For the server:

    gem install treetop eventmachine sequel sqlite3 trollop beefcake

For the dashboard:

     gem install sinatra thin erubis sass

Getting started
===============

To try it out, install all the gems above, and clone the repository. Start the server with

    bin/server [--host host] [--port port]

UState listens on TCP socket host:port, and accepts connections from clients. Start a basic testing client with

    bin/test

The tester spews randomly generated statistics at a server on the default local host and port. To see it in action, run the dashboard:

    cd lib/ustate/dash
    ../../../bin/dash

The client
==========

You can use the git repo, or the gem.

    gem install ustate-client

Then:

    require 'ustate'
    require 'ustate/client'

    # Create a client
    c = UState::Client.new(
      host: "my.host",    # Default localhost
      port: 1234          # Default 55956
    )
    
    # Insert a state
    c << {
      state: "ok",
      service: "My service"
    }

    # Query for states
    c.query.states # => [UState::State(state: 'ok', service: 'My service')]
    c.query('state != "ok"').states # => []

The Dashboard
=============

The dashboard runs a file in the local directory: config.rb. That file can
override any configuration options on the Dash class (hence all Sinatra
configuration) as well as the Ustate client, etc.

    set :port, 6000 # HTTP server on port 6000
    config[:client][:host] = 'my.ustate.server'

It also loads views from the local directory. Sinatra makes it awkward to
compose multiple view directories, so you'll probably want to create your own
view/ and config.rb. I've provided an example stylesheet, layout, and dashboard
in lib/ustate/dash/views--as well as an extensive set of functions for laying
out states corresponding to any query: see lib/ustate/dash/helper/renderer.rb.
The way I figure, you're almost certainly going to want to write your own, so
I'm going to give you the tools you need, and get out of your way.

Protocol
========

A connection to UState is a stream of messages. Each message is a 4 byte
network-endian integer *length*, followed by a Procol Buffers Message of
*length* bytes. See lib/ustate/message.rb for the protobuf particulars.

The server will accept a repeated list of States, and respond with a
confirmation message with either an acknowledgement or an error. Check the
success boolean in the Message.

You can also query states using a very basic expression language. The grammar is specified as a Parsable Expression Grammar in query_string.treetop. Examples include:

    state = "ok"
    (service =~ "disk%") or (state == "critical" and host =~ "%.trioptimum.com")

Search queries will return a message with repeated States matching that expression. An null expression will return no states.

Performance
===========

It's Ruby. It ain't gonna be fast. However, on my 4-year-old core 2 duo, I see >750 inserts/sec or queries/sec. The client is fully threadsafe, and performs well concurrently. I will continue to tune UState for latency and throughput, and welcome patches.

For large installations, I plan to implement a selective forwarder. Local ustate servers can accept high volumes of states from a small set of nodes, and forward updates at a larger granularity to supervisors, and so forth, in a tree. The query language should be able to support proxying requests to the most recent source of a state, so very large sets of services can be maintained at high granularity.

Goals
=====

Immediately, I'll be porting our internal email alerter to UState. Users register for interest in certain types of states or transitions, and receive emails when those events occur.

In the medium term, I'll be connecting UState to Graphite (or perhaps another
graphing tool) for metrics archival and soft-realtime graphs. I have an
internal gnuplot system which is clunky and deserves retirement.

When the protocol and architecture are finalized, I plan to reimplement the server in a faster language.
