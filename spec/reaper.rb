#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'
require 'set'

Bacon.summary_on_exit 

include UState

# Start server
UState::Reaper::INTERVAL = INTERVAL = 0.1
server = Server.new
runner = Thread.new do
  Thread.abort_on_exception = true
  server.start
end

# Wait for server to start
sleep 0.2

describe UState::Reaper do
  before do
    @client = Client.new
    server.index.clear
    server.reaper.targets = {}
  end
  
  should 'expire states by default' do
    @client << {
      service: 'alive'
    }
    @client << {
      service: 'dead',
      time: (Time.now - server.reaper.default - 1).to_i
    }

    sleep INTERVAL * 2
    
    @client.query('service = "dead"').states.should.be.nil
    @client.query('service = "alive"').states.size.should == 1
  end
  
  should 'expire only selected states with no default' do
    server.reaper.default = nil
    server.reaper.reap 'host != "immortal"', 10
    server.reaper.reap 'host = "long"', 20
    @client << { host: 'short', service: 'dead', time: (Time.now - 11).to_i}
    @client << { host: 'short', service: 'alive', time: (Time.now - 9).to_i}
    @client << { host: 'long', service: 'dead', time: (Time.now - 21).to_i}
    @client << { host: 'long', service: 'alive', time: (Time.now - 19).to_i}
    @client << { host: 'immortal', service: 'alive', time: (Time.now - 999999).to_i}

    sleep INTERVAL * 2
    
    @client.query('service = "dead"').states.should.be.nil
    @client.query('service = "alive"').states.map { |s| s.host }.to_set.should == ['short', 'long', 'immortal'].to_set
  end
  
  should 'not expire selected states' do
    server.reaper.default = 15
    server.reaper.reap! 'host = "immortal"', nil
    server.reaper.reap! 'host = "short"', 10
    server.reaper.reap! 'host = "long"', 20
    server.reaper.compile

    @client << { host: 'short', service: 'alive', time: (Time.now - 9).to_i}
    @client << { host: 'short', service: 'dead', time: (Time.now - 11).to_i}
    @client << { host: 'default', service: 'alive', time: (Time.now - 14).to_i}
    @client << { host: 'default', service: 'dead', time: (Time.now - 16).to_i}
    @client << { host: 'long', service: 'alive', time: (Time.now - 19).to_i}
    @client << { host: 'long', service: 'dead', time: (Time.now - 21).to_i}
    @client << { host: 'immortal', service: 'alive', time: (Time.now - 999999).to_i}

    sleep INTERVAL * 2
    
    @client.query('service = "dead"').states.should.be.nil
    @client.query('service = "alive"').states.map { |s| s.host }.to_set.should == ['short', 'long', 'default', 'immortal'].to_set
  end
end
