# Instantiated by EventMachine for each new connection
# Mostly from Thin.
class UState::Server::Connection < EventMachine::Connection
  attr_accessor :backend
  attr_accessor :index

  # Called to prepare the connection for a request
  def post_init
    @state = :length
    @buffer = ""
  end

  # Called when data is received
  def receive_data(data = '')
    @buffer << data
   
    case @state
    when :length
      # Length header
      if @buffer.bytesize >= 4
        @length = @buffer.slice!(0,4).unpack('N').first
        @state = :data
        receive_data unless @buffer.empty?
      end
    when :data
      # Data
      if @buffer.bytesize >= @length
        receive_message @buffer.slice!(0, @length)
        @state = :length
        receive_data unless @buffer.empty?
      end
    end
  end

  # Called with a message type and data.
  def receive_message(data)
    begin
      message = UState::Message.decode data
      if states = message.states
        # State update
        states.each do |state|
          @index << state
        end
        send UState::Message.new(ok: true)
      elsif q = message.query
        res = @index.query(q)
        send UState::Message.new(ok: true, states: res)
      else
        send UState::Message.new(ok: false, error: "unknown message type")
      end
    rescue Exception => e
      m = UState::Message.new(ok: false, error: e.message)
      send m
    end
  end

  def send(message)
    send_data message.encode_with_length
  end

  # Called when the connection is unbound from the socket and can no longer be
  # used to process requests.
  def unbind
    @backend.connection_finished self
  end

  def remote_address
    socket_address
  end

  def terminate_request
    close_connection_after_writing rescue nil
  end

  protected

  def socket_address
    Socket.unpack_sockaddr_in(get_peername)[1]
  end
end
