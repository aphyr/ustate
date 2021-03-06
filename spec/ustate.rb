#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'
require 'set'

Bacon.summary_on_exit 

include UState

# Start server
server = Server.new
server.index.insert_times_interval = 0.1
server.index.insert_rate_interval = 0.1
runner = Thread.new do
  Thread.abort_on_exception = true
  server.start
end

# Let the server start listening
sleep 0.2

describe UState::Client do
  before do
    @client = Client.new
    server.index.clear
  end

  should 'send a state' do
    res = @client << {
      state: 'ok',
      service: 'test',
      description: 'desc',
      metric_f: 1.0
    }
    
    res.ok.should == true
  end
  
  should 'send a state once' do
    @client << {
      state: 'ok',
      service: 'test'
    }

    r = @client << {
      state: 'error',
      service: 'test',
      once: true
    }

    @client.query('service = "test"').states.first.state.should == 'ok'
  end

  should 'send a state with a time' do
    t = Time.now.to_i - 10
    @client << {
      state: 'ok',
      service: 'test',
      time: t
    }
    @client.query('service = "test"').states.first.time.should == t

    @client << State.new(
      state: 'ok',
      service: 'test',
      time: t
    )
    @client.query('service = "test"').states.first.time.should == t
  end

  should 'send a state without time' do
    @client << {
      state: 'ok',
      service: 'test'
    }
    @client.query('service = "test"').states.first.time.should == Time.now.to_i

    @client << State.new(
      state: 'ok',
      service: 'test'
    )
    @client.query('service = "test"').states.first.time.should == Time.now.to_i
  end
  
  should "query states" do
    @client << { state: 'critical', service: '1' }
    @client << { state: 'warning', service: '2' }
    @client << { state: 'critical', service: '3' }
    @client.query.states.
      map(&:service).to_set.should.superset ['1', '2', '3'].to_set
    @client.query('state = "critical"').states.
      map(&:service).to_set.should == ['1', '3'].to_set
  end

  it '[]' do
    @client['state = "critical"'].should == []
    @client << {state: 'critical'}
    @client['state = "critical"'].first.state.should == 'critical'
  end

  should 'query quickly' do
    t1 = Time.now
    total = 1000
    total.times do |i|
      @client.query('state = "critical"')
    end
    t2 = Time.now

    server.index.stop
    t3 = Time.now
    server.index.stop

    rate = total / (t2 - t1)
    puts
    puts "#{rate} queries/sec"
    rate.should > 100
  end
 
  should 'be threadsafe' do
    concurrency = 10
    per_thread = 200
    total = concurrency * per_thread

    t1 = Time.now
    (0...concurrency).map do |i|
      Thread.new do
        per_thread.times do
          @client.<<({
            state: 'ok',
            service: 'test',
            description: 'desc',
            metric_f: 1.0
          }).ok.should.be.true
        end
      end
    end.each do |t|
      t.join
    end
    t2 = Time.now
   
    server.index.stop
    t3 = Time.now
    server.index.start

    rate = total / (t2 - t1)
    puts
    puts "#{rate} inserts/sec"
    rate.should > 100
  end

  should 'survive inactivity' do
    @client.<<({
      state: 'warning',
      service: 'test',
    })

    sleep 5

    @client.<<({
      state: 'warning',
      service: 'test',
    }).ok.should.be.true
  end

  should 'survive local close' do
    @client.<<({
      state: 'warning',
      service: 'test',
    }).ok.should.be.true
    
    @client.socket.close
    
    @client.<<({
      state: 'warning',
      service: 'test',
    }).ok.should.be.true
  end

  should 'survive remote close' do
    @client.<<({
      state: 'warning',
      service: 'test',
    }).ok.should.be.true
    
    server.stop
    sleep 0.25
    server.start
    
    @client.<<({
      state: 'warning',
      service: 'test',
    }).ok.should.be.true
  end

  should 'know own rate' do
    sleep 0.1
    @client << {service: 'test', state: 'ok'}
    sleep 0.1
    @client.query('service = "ustate insert rate"').states.first.metric.should > 0
    @client.query('service = "ustate insert 50"').states.first.metric.should > 0
    @client.query('service = "ustate insert 95"').states.first.metric.should > 0
    @client.query('service = "ustate insert 99"').states.first.metric.should > 0
  end
end
