#!/usr/bin/env ruby

# Connects to a server and populates it with a constant stream of events for
# testing.

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/client'
require 'pp'

class UState::TestEvent
  attr_accessor :client, :hosts, :services, :states
  def initialize
    @hosts = [nil] + (0...10).map { |i| "host#{i}" }
    @hosts = ['test']
    @services = %w(per)
    @states = {}
    @client = UState::Client.new(port: 55955)
  end

  def evolve(state)
    m = rand
    s = case m
    when 0...0.75
      'ok'
    when 0.75...0.9
      'warning'
    when 0.9..1.0
      'critical'
    end

    UState::Event.new(
      metric_f: m,
      state: s,
      host: state.host,
      service: state.service,
      description: "at #{Time.now}"
    )
  end
  
  def tick
#    pp @states
    hosts.product(services).each do |id|
      client << (states[id] = evolve(states[id]))
    end
  end

  def run
    start
    loop do
#      sleep 0.01
      tick
    end
  end

  def start
    hosts.product(services).each do |host, service|
      states[[host, service]] = UState::Event.new(
        metric_f: 0.5,
        state: 'ok',
        description: "Starting up",
        host: host,
        service: service
      )
    end
  end
end

UState::TestEvent.new.run
