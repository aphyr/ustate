module UState
  class Graphite
    # Forwards states to Graphite.
    HOST = '127.0.0.1'
    PORT = 2003

    attr_accessor :query
    attr_accessor :host
    attr_accessor :port
    def initialize(index, opts = {})
      index.on_state &method(:receive)
      @query = opts[:query]
      @host = opts[:host] || HOST
      @port = opts[:port] || PORT
      @locket = Mutex.new
    end

    def connect
      @socket = TCPSocket.new(@host, @port)
    end

    # Formats a state into a Graphite metric path.
    def path(state)
      if state.host
        host = state.host.split('.').reverse.join('.')
        "#{host}.#{state.service.gsub(' ', '.')}"
      else
        state.service.gsub(' ', '.')
      end
    end

    def graph(q)
      if @query
        @query = Query::Or.new(@query, Query.query(q))
      else
        @query = Query.query q
      end
    end

    def forward(state)
      string = "#{path(state)} #{state.metric} #{state.time}"
      if string["\n"]
        raise ArgumentError, "#{string} has a newline"
      end
      with_connection do |s|
        s.puts string
      end
    end

    def receive(state)
      Thread.new do
        if @query === state
          forward state
        end
      end
    end

    def with_connection
      tries = 0
      @locket.synchronize do
        begin
          tries += 1
          yield (@socket or connect)
        rescue IOError => e
          raise if tries > 3
          connect and retry
        rescue Errno::EPIPE => e
          raise if tries > 3
          connect and retry
        rescue Errno::ECONNREFUSED => e
          raise if tries > 3
          connect and retry
        rescue Errno::ECONNRESET => e
          raise if tries > 3
          connect and retry
        end
      end
    end
  end
end
