#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ustate'))
require 'ustate/server'
require 'ustate/client'
require 'bacon'
require 'sequel'
require 'ustate/query/optimizer'

Bacon.summary_on_exit 

include UState

describe UState::Query::Optimizer do
  def parse(string)
    tree = QueryStringParser.new.parse string
    tree.should.not.be.nil
    tree.query
  end

  def m max, min
    it max do
      Query::Optimizer[parse(max)].should == parse(min)
    end
  end

  # Literals
  m "true", "true"
  m "false", "false"

  # Boolean conjunctions
  m "false and false", "false"
  m "true and false", "false"
  m "false and true", "false"
  m "true and true", "true"
  m "false or false", "false"
  m "true or false", "true"
  m "false or true", "true"
  m "true or true", "true"
  
  # Redundant boolean literals
  m "true and state = 2", "state = 2"
  m "false or state = 2", "state = 2"
end
