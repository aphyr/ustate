# Stolen from Thin

class UState::Server
  class Backends::TCP < Backends::Base
    require 'socket'
   
    attr_accessor :host, :port

    HOST = '127.0.0.1'
    PORT = 55956

    def initialize(opts = {})
      @host = opts[:host] || HOST
      @port = opts[:port] || PORT
      super opts
    end

    # Connect the server
    def connect
      @server.log.info "Listening on #{@host}:#{@port}"
      @signature = EventMachine.start_server(@host, @port, Connection, &method(:initialize_connection))
    end

    # Stops server
    def disconnect
      EventMachine.stop_server @signature
    end

    def to_s
      "#{@host}:#{@port}"
    end
  end
end
