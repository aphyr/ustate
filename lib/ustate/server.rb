module UState
  class Server
    # A server binds together Backends, an Index, and Sinks.
    # - Backends spawn Connections with EM.
    # - Connections receive messages from clients, and pass States to the Index.
    # - The Index aggregates states together and informs Sinks.
 
    class Error < RuntimeError; end

    require 'eventmachine' 
    require 'ustate/server/connection'
    require 'ustate/server/index'
    require 'ustate/server/backends'
    require 'treetop'
    require 'ustate/query_string'
    require 'ustate/query/ast'

    attr_accessor :backends
    attr_accessor :index
    attr_writer :aggregator
    attr_writer :emailer
    attr_writer :graphite
   
    def initialize(opts = {})
      # Backends
      @backends = []
      b = Backends::TCP.new opts
      b.server = self
      @backends << b

      @index = Index.new

      setup_signals
    end

    def aggregator(opts = {})
      require 'ustate/aggregator'
      @aggregator ||= UState::Aggregator.new(@index, opts)
    end

    def emailer(opts = {})
      require 'ustate/emailer'
      @emailer ||= UState::Emailer.new(@index, opts)
    end

    def graphite(opts = {})
      require 'ustate/graphite'
      @graphite ||= UState::Graphite.new(@index, opts)
    end

    def start
      @index.start
     
      # Right now b.start blocks... should look into EM 
      @backends.map do |b|
        b.start
      end
    end

    def stop
      @backends.map do |b|
        if b.running?
          b.stop
        else
          stop!
        end
      end

      @index.stop
    end

    def stop!
      @backends.map do |b|
        b.stop!
      end

      @index.stop!
    end

    def setup_signals
      trap('INT') { stop! }
      trap('TERM') { stop }
    end
  end
end
