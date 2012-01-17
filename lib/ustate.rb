module UState
  $LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

  require 'beefcake'
  require 'ustate/version'
  require 'ustate/state'
  require 'ustate/event'
  require 'ustate/query'
  require 'ustate/message'
end
