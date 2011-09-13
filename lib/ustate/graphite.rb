module UState
  class Graphite
    # Forwards states to Graphite.
    HOST = '127.0.0.1'
    PORT = 2003
    INTERVAL = 10

    attr_accessor :query
    attr_accessor :host
    attr_accessor :port
    attr_accessor :interval

    def initialize(index, opts = {})
      @index = index
      @query = opts[:query]
      @host = opts[:host] || HOST
      @port = opts[:port] || PORT
      @interval = opts[:interval] || INTERVAL
      @locket = Mutex.new

      start
    end

    def connect
      @socket = TCPSocket.new(@host, @port)
    end

    def graph(q)
      if @query
        @query = "(#{@query}) or (#{q})"
      else
        @query = q
      end
    end

    def forward(state)
      # Figure out what time to use.
      present = Time.now.to_i
      if (present - state.time) >= INTERVAL
        time = present
      else
        time = state.time
      end

      # Construct message
      string = "#{path(state)} #{state.metric} #{state.time}"
      
      # Validate string
      if string["\n"]
        raise ArgumentError, "#{string} has a newline"
      end

      with_connection do |s|
        s.puts string
      end
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

    def start
      @runner = Thread.new do
        loop do
          @index.query(Query.new(string: @query)).each do |state|
            forward state
          end
          sleep @interval
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
