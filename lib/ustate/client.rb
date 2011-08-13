class UState::Client
  class InvalidResponse < RuntimeError; end
  
  require 'thread'
  require 'time'

  HOST = '127.0.0.1'
  PORT = 55956

  TYPE_STATE = 1

  def initialize(opts = {})
    @host = opts[:host] || HOST
    @port = opts[:port] || PORT
    @locket = Mutex.new
  end

  def <<(state_opts)
    # Create state
    state = UState::State.new(state_opts)
    state.time ||= Time.now.iso8601
    state.host ||= Socket.gethostname

    message = UState::Message.new :state => state

    # Transmit
    with_connection do |s|
      s << message.encode_with_length
      read_message s
    end
  end

  # Read a message from a stream
  def read_message(s)
    if buffer = s.read(4) and buffer.size == 4
      length = buffer.unpack('N').first
      UState::Message.decode s.read(length)
    else
      raise InvalidResponse, "unexpected EOF"
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

  def with_connection
    tries = 0
    begin
      tries += 1
      @locket.synchronize do
        yield (@socket or connect)
      end
    rescue Errno::ECONNREFUSED => e
      raise unless tries > 3
      connect and retry
    rescue Errno::ECONNRESET => e
      raise unless tries > 3
      connect and retry
    end
  end
end
