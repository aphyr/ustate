#!/usr/bin/env ruby

puts `cd lib/ustate; tt query_string.treetop`

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'
require 'sequel'

Bacon.summary_on_exit 

include UState

describe UState::QueryString do
  def parse(string)
    tree = QueryStringParser.new.parse string
    tree.should.not.be.nil
    tree
  end

  def t(string, parsed = nil)
    it "Parse #{string}" do
      parse string
    end
  end

  def ds
    index = Server::Index.new
    index.db[:states]
  end

  def s(string, dataset)
    it "SQL #{string}" do
      ds.filter(parse(string).sql).sql.should == (dataset.sql rescue dataset)
    end
  end

  def m(string, good = [], bad = [])
    it "Query#=== for #{string}" do
      q = parse(string).query
      good.each do |state|
        q.should === State.new(state)
      end
      bad.each do |state|
        q.should.not === State.new(state)
      end
    end
  end

  t 'state = "test"'
  t 'state = 0.25'
  t 'state != 2'
  t 'state =~ "%foo"'
  t 'state = 2 or state = 3'
  t 'state = 2 or state = 3 or state = 5'
  t 'state = 2 or state = 3 and state = 2'
  t 'state = 2 and state = 3 or state = 3'
  t 'state = 2 and state = 3 or state = 3 and state = 2 or state = 4 and state = 2 or state = 5'
  t '(state = 2 or state = 3) and (state = 3 or (state = 3))'

  s 'state = nil', ds.filter(:state => nil)
  s 'state = null', ds.filter(:state => nil)
  s 'state = "test"', ds.filter(:state => 'test')
  s 'state = 2', ds.filter(:state => 2)
  s 'metric_f > 1', ds.filter { |s| s.metric_f > 1 }
  s 'metric_f >= 1', ds.filter { |s| s.metric_f >= 1 }
  s 'metric_f < 1', ds.filter { |s| s.metric_f < 1 }
  s 'metric_f <= 1', ds.filter { |s| s.metric_f <= 1 }
  s 'state = -1.24', ds.filter(:state => -1.24)
  s 'state =~ "%foo%"', ds.filter(:state.like '%foo%')
  s 'not state = "foo"', ds.filter(state: 'foo').invert
  s 'state = 2 and host = "bar"', ds.filter(state: 2, host: "bar")
  s 'state = 2 and host != "bar" or service = "test"', ds.filter(state: 2).exclude(host: 'bar').or(service: 'test')
  s '(state = 1 or state = 2) and (state = 3 or state = 4)', 
    "SELECT * FROM `states` WHERE (((`state` = 1) OR (`state` = 2)) AND ((`state` = 3) OR (`state` = 4)))"
  s 'state = 1 or (state = 2 and (state = 3 or state = 4))', 
    "SELECT * FROM `states` WHERE ((`state` = 1) OR ((`state` = 2) AND ((`state` = 3) OR (`state` = 4))))"
  s '((state = 1 or state = 2) and state = 3) or state = 4', 
    "SELECT * FROM `states` WHERE ((((`state` = 1) OR (`state` = 2)) AND (`state` = 3)) OR (`state` = 4))"

  # Test AST matching
  m 'state = "test"', [{state: 'test'}], [{}, {state: 'bad'}]
  m 'metric_f = 2', [{metric_f: 2.0}], [{}, {metric_f: 3.0}]
  m 'metric_f = 2.0', [{metric_f: 2.0}], [{}, {metric_f: 3.0}]
  m 'state != "test"', [{}, {state: 'bad'}], [{state: 'test'}]
  m 'state =~ "a"', [{state: 'a'}], [{}, {state: ' a'}, {state: 'a '}]
  m 'metric_f > 0', [{metric_f: 0.1}], [{}, {metric_f: 0}]
  m 'metric_f >= 0', [{metric_f: 0.1}, {metric_f: 0}], [{}, {metric_f: -1}]
  m 'metric_f < 0', [{metric_f: -0.1}], [{}, {metric_f: 0}]
  m 'metric_f <= 0', [{metric_f: -0.1}, {metric_f: 0}], [{}, {metric_f: 1}]
  m 'not host = "foo"', [{}, {host: 'bar'}], [{host: "foo"}] 
end
