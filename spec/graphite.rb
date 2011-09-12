#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'

include UState

# Start server
server = Server.new
runner = Thread.new do
  Thread.abort_on_exception = true
  server.start
end

# Start emailer
server.graphite.graph 'service = "graphite"'

# Let the server start listening
sleep 0.2

client = Client.new
metric = 0.0

loop do
  client << {
    service: 'graphite',
    state: 'ok',
    metric_f: [0.0, metric + rand - 0.5].max
  }
  sleep 1
end
