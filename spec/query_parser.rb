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
    tree = State::QueryStringParser.new.parse string
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

  s 'state = "test"', ds.filter(:state => 'test')
  s 'state = 2', ds.filter(:state => 2)
  s 'state = -1.24', ds.filter(:state => -1.24)
  s 'state =~ "%foo%"', ds.filter(:state.like '%foo%')
  s 'state = 2 and host = "bar"', ds.filter(state: 2, host: "bar")
  s 'state = 2 and host != "bar" or service = "test"', ds.filter(state: 2).exclude(host: 'bar').or(service: 'test')
  s '(state = 1 or state = 2) and (state = 3 or state = 4)', 
    "SELECT * FROM `states` WHERE (((`state` = 1) OR (`state` = 2)) AND ((`state` = 3) OR (`state` = 4)))"
  s 'state = 1 or (state = 2 and (state = 3 or state = 4))', 
    "SELECT * FROM `states` WHERE ((`state` = 1) OR ((`state` = 2) AND ((`state` = 3) OR (`state` = 4))))"
  s '((state = 1 or state = 2) and state = 3) or state = 4', 
    "SELECT * FROM `states` WHERE ((((`state` = 1) OR (`state` = 2)) AND (`state` = 3)) OR (`state` = 4))"
end
