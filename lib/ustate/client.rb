class UState::Client
  class Error < RuntimeError; end
  class InvalidResponse < Error; end
  class ServerError < Error; end
  
  require 'thread'
  require 'socket'
  require 'time'

  HOST = '127.0.0.1'
  PORT = 55956

  TYPE_STATE = 1

  def initialize(opts = {})
    @host = opts[:host] || HOST
    @port = opts[:port] || PORT
    @locket = Mutex.new
  end

  # Send a state
  def <<(state_opts)
    # Create state
    state = UState::State.new(state_opts)
    state.time ||= Time.now.utc.to_i
    state.host ||= Socket.gethostname

    message = UState::Message.new :states => [state]

    # Transmit
    with_connection do |s|
      s << message.encode_with_length
      read_message s
    end
  end

  def connect
    @socket = TCPSocket.new(@host, @port)
  end

  def close
    @locket.synchronize do
      @socket.close
    end
  end

  def connected?
    not @socket.closed?
  end

  # Ask for states
  def query(string = nil)
    message = UState::Message.new query: UState::Query.new(string: string)
    with_connection do |s|
      s << message.encode_with_length
      read_message s
    end
  end

  # Read a message from a stream
  def read_message(s)
    if buffer = s.read(4) and buffer.size == 4
      length = buffer.unpack('N').first
      begin
        str = s.read length
        message = UState::Message.decode str
      rescue => e
        puts "Message was #{str.inspect}"
        raise
      end
      
      unless message.ok
        puts "Failed"
        raise ServerError, message.error
      end
      
      message
    else
      raise InvalidResponse, "unexpected EOF"
    end
  end

  # Yields a connection in the block.
  def with_connection
    tries = 0
    begin
      tries += 1
      @locket.synchronize do
        yield (@socket or connect)
      end
    rescue Errno::EPIPE => e
      raise unless tries > 3
      connect and retry
    rescue Errno::ECONNREFUSED => e
      raise unless tries > 3
      connect and retry
    rescue Errno::ECONNRESET => e
      raise unless tries > 3
      connect and retry
    end
  end
end
