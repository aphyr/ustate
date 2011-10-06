#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'ustate/aggregator'
require 'bacon'
require 'set'

Bacon.summary_on_exit 

include UState

# Start server
server = Server.new
runner = Thread.new do
  Thread.abort_on_exception = true
  server.start
end

# Let the server start listening
sleep 0.2

describe UState::Aggregator do
  before do
    @client = Client.new
    server.index.clear
    server.aggregator = nil
  end
  
  should 'sum states' do
    server.aggregator.sum 'service =~ "summand %"', service: 'sum'
    @client << {
      service: 'summand 1',
      metric_f: 1.0,
      state: 'ok'
    }
    @client << {
      service: 'summand 2',
      metric_f: 1.0,
      state: 'ok'
    }
    @client << {
      service: 'summand 3',
      metric_f: 2.0,
      state: 'warning'
    }
    
    sleep(server.aggregator.interval * 2)
   
    s = @client.query('service = "sum"').states.first
    s.metric.should == 4.0
    s.state.should == 'ok'
  end

  should 'average states' do
    server.aggregator.average 'service =~ "part %"', State.new(service: 'average')
    @client << {
      service: 'part 1',
      metric_f: 1.0,
      state: 'ok'
    }
    @client << {
      service: 'part 2',
      metric_f: 1.0,
      state: 'ok'
    }
    @client << {
      service: 'part 3',
      metric_f: 2.0,
      state: 'warning'
    }
    
    sleep(server.aggregator.interval * 2)
   
    s = @client.query('service = "average"').states.first
    (1.3333333 - s.metric).should < 0.0001
    s.state.should == 'ok'
  end

  should 'fold over hosts' do
    server.aggregator.sum_over_hosts 'host =~ "m%"'

    @client << { service: 'a', host: 'm1', metric_f: 1.0}
    @client << { service: 'a', host: 'm2', metric_f: 1.0}
    @client << { service: 'b', host: 'm1', metric_f: 1.0}
    @client << { service: 'b', host: 'm2', metric_f: 1.0}

    sleep(server.aggregator.interval * 2)

    @client.query('service = "a" and host = null').states.first.metric_f.should == 2.0
  end
end
