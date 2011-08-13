module UState
  class Server
    # A server binds together Backends, an Index, and Sinks.
    # - Backends spawn Connections with EM.
    # - Connections receive messages from clients, and pass States to the Index.
    # - The Index aggregates states together and informs Sinks.
  
    require 'eventmachine' 
    require 'ustate/server/connection'
    require 'ustate/server/index'
    require 'ustate/server/backends'

    attr_accessor :backends
    attr_accessor :index
   
    def initialize
      # Backends
      @backends = []
      b = Backends::TCP.new
      b.server = self
      @backends << b

      @index = Index.new

      setup_signals
    end

    def start
      @backends.all? do |b|
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
    end

    def stop!
      @backends.map do |b|
        b.stop!
      end
    end

    def setup_signals
      trap('INT') { stop! }
      trap('TERM') { stop }
    end
  end
end
