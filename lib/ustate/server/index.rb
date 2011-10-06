module UState
  class Server::Index
    # Combines state messages. Responds to queries for particular states.
    # Forwards messages to various receivers.
    # Inserts are NOT threadsafe.
    
    class ParseFailed < Server::Error; end

    require 'sequel'

    THREADS = 1000
    BUFFER_SIZE = 10

    # Update metrics every
    INSERT_RATE_INTERVAL = 5
    INSERT_TIMES_INTERVAL = 5
    
    attr_reader :db, :queue
    attr_accessor :insert_rate_interval
    attr_accessor :insert_times_interval

    def initialize(opts = {})
      @db = Sequel.sqlite

      @server = opts[:server]
      @threads = opts[:threads] || THREADS
      @pool = []

      @on_state_change = []
      @on_state_once = []
      @on_state = []

      @insert_rate_interval = opts[:insert_rate_interval] || INSERT_RATE_INTERVAL
      @insert_times_interval = opts[:insert_times_interval] || INSERT_TIMES_INTERVAL
      setup_db
    end

    def clear
      setup_db
    end

    def <<(s)
      t0 = Time.now
      process s
      dt = Time.now - t0
      @insert_times << dt
      @insert_rate << 1
    end

    # Removes a state from the index.
    #
    # Right now state is anything which responds to #host and #service.
    # I'll probably evolve the index to support arbitrary operations on all
    # states matching a query, but haven't thought out the API.
    def delete(state)
      @db[:states].filter(host: state.host, service: state.service).delete
    end

    def thread(s)
      Thread.new do
        process s
        @pooltex.synchronize do
          @pool.delete Thread.current
        end
      end
    end

    def on_state_change(old = nil, new = nil, &block)
      if block_given?
        @on_state_change |= [block]
      else
        @on_state_change.each do |callback|
          callback.call old, new
        end
      end
    end

    def on_state_once(state = nil, &block)
      if block_given?
        @on_state_once |= [block]
      else
        @on_state_once.each do |callback|
          callback.call state
        end
      end
    end

    def on_state(state = nil, &block)
      if block_given?
        @on_state |= [block]
      else
        @on_state.each do |callback|
          callback.call state
        end
      end
    end

    def process(s)
      if s.once
        on_state_once s
        return on_state s
      end

      if current = @db[:states][host: s.host, service: s.service]
        # Update
        if current[:time] <= s.time
          if current[:state] != s.state
            on_state_change row_to_state(current), s
          end           

          # Update
          @db[:states].filter(host: s.host, service: s.service).update(
            state: s.state,
            time: s.time,
            description: s.description,
            metric_f: s.metric_f
          )
        end
      else
        # Insert
        @db[:states].insert(
          host: s.host,
          service: s.service,
          state: s.state,
          time: s.time,
          description: s.description,
          metric_f: s.metric_f
        )
      end

      on_state s
    end

    # Returns an array of States matching Query.
    def query(q)
      parser = QueryStringParser.new
      if q.string
        unless expression = parser.parse(q.string)
          raise ParseFailed, "error parsing #{q.string.inspect} at line #{parser.failure_line}:#{parser.failure_column}: #{parser.failure_reason}"
        end
        filter = expression.sql
      else
        # No string? All states.
        filter = true
      end
      
      ds = @db[:states].filter filter
      ds.all.map do |row|
        row_to_state row
      end
    end

    # Converts a row to a State
    def row_to_state(row)
      State.new(row)
    end
    
    def setup_db
      @db.drop_table :states rescue nil
      @db.create_table :states do
        String :host
        String :service
        String :state
        String :description, :text => true
        Integer :time
        Float :metric_f
        primary_key [:host, :service]
      end
    end

    def start
      stop!
      @pool = []

      @insert_rate = MetricThread.new(Mtrc::Rate) do |r|
        self << State.new(
          service: "ustate insert rate",
          state: "ok",
          host: Socket.gethostname,
          time: Time.now.to_i,
          metric_f: r.rate.to_f,
        )
      end
      @insert_rate.interval = @insert_rate_interval
      
      @insert_times = MetricThread.new(Mtrc::SortedSamples) do |r|
        self << State.new(
          service: "ustate insert 50",
          state: "ok",
          host: Socket.gethostname,
          time: Time.now.to_i,
          metric_f: r % 50,
        )
        self << State.new(
          service: "ustate insert 95",
          state: "ok",
          host: Socket.gethostname,
          time: Time.now.to_i,
          metric_f: r % 95,
        )
        self << State.new(
          service: "ustate insert 99",
          state: "ok",
          host: Socket.gethostname,
          time: Time.now.to_i,
          metric_f: r % 99,
        )
      end
      @insert_times.interval = @insert_times_interval
    end

    # Finish up
    def stop
      @insert_rate.stop rescue nil
      @insert_times.stop rescue nil
    end

    def stop!
      @pool.each do |thread|
        thread.kill
      end
    end
  end
end
