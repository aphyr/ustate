#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'ustate/auto_state'
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

describe UState::AutoState do
  before do
    @client = Client.new
    @a = AutoState.new @client, :service => 'test'
    server.index.clear
  end

  should 'send description' do
    @a.description = 'desc'
    @client.query('service = "test"').states.first.description.should == 'desc'
  end
  
  should 'send metric_f' do
    @a.metric_f = 1.0
    @client.query('service = "test"').states.first.metric_f.should == 1.0
  end
  
  should 'send state' do
    @a.state = 'not ok'
    @client.query('service = "test"').states.first.state.should == 'not ok'
  end
  
  should 'send service' do
    @a.service = 'different'
    @client.query('service = "different"').states.first.state.should == nil
  end

  should 'send once' do
    @a.state = 'ok'

    LOG ||= []
    LOG.clear

    server.index.on_state_once do |s|
      LOG << s
    end

    @a.once :state => 'error'
    
    LOG.size.should == 1
    LOG[0].service.should == 'test'
    LOG[0].state.should == 'error'

    @a.state.should == 'ok'
    @client.query('service = "test"').states.first.state.should == 'ok'
  end
end
