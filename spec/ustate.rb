#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'

Bacon.summary_on_exit 

include UState

server = Server.new
runner = Thread.new do
  Thread.abort_on_exception = true
  server.start
end

describe UState::Client do
  before do
    @client = Client.new
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

  should 'be threadsafe' do
    concurrency = 10
    per_thread = 200
    total = concurrency * per_thread

    t1 = Time.now
    (0..concurrency).map do |i|
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
    puts "#{rate}/sec"    
    rate.should > 1000
  end
end
