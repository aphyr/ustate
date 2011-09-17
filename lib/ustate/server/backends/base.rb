# Largely stolen from Thin

class UState::Server::Backends::Base
  TIMEOUT = 5
  MAXIMUM_CONNECTIONS = 1024
  MAX_CONNECTIONS = 512

  attr_accessor :server
  attr_accessor :timeout
  attr_accessor :maximum_connections
  attr_writer :ssl, :ssl_options
  def ssl?; @ssl; end

  def initialize(opts = {})
    @connections = []
    @server = opts[:server]
    @timeout = opts[:timeout] || TIMEOUT
    @maximum_connections = opts[:maximum_connections] || MAXIMUM_CONNECTIONS
  end

  def start
    @stopping = false
    starter = proc do
      connect
      @running = true
    end

    # Allow for early run-up of eventmachine
    if EventMachine.reactor_running?
      starter.call
    else
      EventMachine.run &starter
    end
  end

  # Graceful stop
  def stop
    @running = false
    @stopping = true

    # Stop accepting connections
    disconnect
    stop! if @connections.empty?
  end

  # Force stop
  def stop!
    @running = false
    @stopping = false

    EventMachine.stop if EventMachine.reactor_running?
    @connections.each { |connection| connection.close_connection }
    close
  end

  # Configure backend
  def config
    EventMachine.epoll

    @maximum_connections =
      EventMachine.set_descriptor_table_size(@maximum_connections)
  end

  # Free up resources used by the backend
  def close
  end

  def running?
    @running
  end

  # Called by a connection when it's unbound
  def connection_finished(connection)
    @connections.delete connection

    # Finalize graceful stop if there's no more active connections.
    stop! if @stopping and @connections.empty?
  end

  # No connections?
  def empty?
    @connections.empty?
  end

  # No of connections
  def size
    @connections.size
  end

  protected

  # Initialize a new connection to a client
  def initialize_connection(connection)
    connection.backend = self
    connection.index = @server.index 
    connection.comm_inactivity_timeout = @timeout

#    if @ssl
#      connection.start_tls(@ssl_options
#    end
    
    @connections << connection
  end
end
