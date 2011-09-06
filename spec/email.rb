#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'
require 'set'

Bacon.summary_on_exit 

unless email = ARGV[0]
  puts "I need an email, please."
  exit!
end

include UState

# Start server
server = Server.new
runner = Thread.new do
  Thread.abort_on_exception = true
  server.start
end

# Start emailer
server.emailer from: "ustate@aphyr.com"
server.emailer.tell email, 'state = "error"'
server.emailer.tell email, 'service =~ "special %"'

# Let the server start listening
sleep 0.2

describe UState::Client do
  before do
    @client = Client.new
    server.index.clear
  end

  should 'send email' do
    r = @client << {
      state: 'ok',
      once: true,
      service: 'special 1',
      description: 'desc',
      metric_f: 1.0
    }
    r.ok.should.be.true
    sleep 0.1
  end

  should 'notify once' do
    LOG ||= []
    LOG.clear

    emailer = server.emailer
    def emailer.email(to, state)
      LOG << [to, state]
    end

    s = {state: 'error', host: nil, service: 'test', once: true}
    @client << s
    sleep 0.25
    LOG.size.should == 1
    LOG[0][0].should == email
    LOG[0][1].state.should == 'error'
  end

  should 'notify on change' do
    LOG ||= []
    LOG.clear

    emailer = server.emailer
    def emailer.email(to, state)
      LOG << [to, state]
    end

    @client << {state: 'ok', host: nil, service: 'test'}
    @client << {state: 'ok', host: nil, service: 'test'}
    @client << {state: 'error', host: nil, service: 'test'}
    @client << {state: 'error', host: nil, service: 'test'}
    sleep 0.25
    LOG.size.should == 1
    LOG[0][0].should == email
    LOG[0][1].state.should == 'error'
  end
end
