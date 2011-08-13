#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'

Bacon.summary_on_exit 

include UState

@server = Server.new
@runner = Thread.new do
  Thread.abort_on_exception = true
  @server.start
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
end
