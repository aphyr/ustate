#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'
require 'set'

Bacon.summary_on_exit 

email = ARGV[0] or raise ArgumentError, "I need an email, please."

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
      state: 'error',
      once: true,
      service: 'test',
      description: 'desc',
      metric_f: 1.0
    }
    r.ok.should.be.true
  end

  should 'notify once' do
    LOG = []
    emailer = server.emailer
    def emailer.email(to, state)
      puts "Called with #{to.inspect}, #{state.inspect}"
      LOG << [to, state]
    end

    @client << {state: 'error', host: nil, service: 'test', once: true}
    sleep 0.25
    LOG.size.should == 1
    LOG[1][1].should =~ /Subject: test transient error/
  end

  should 'notify on change' do
  end
end
