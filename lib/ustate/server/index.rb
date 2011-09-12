module UState
  class Server::Index
    # Combines state messages. Responds to queries for particular states.
    # Forwards messages to various receivers.
    # Inserts are NOT threadsafe.
    
    class ParseFailed < Server::Error; end

    require 'sequel'

    THREADS = 1000
    BUFFER_SIZE = 10
    
    attr_reader :db, :queue 

    def initialize(opts = {})
      @db = Sequel.sqlite

      @threads = opts[:threads] || THREADS
      @pool = []

      @on_state_change = []
      @on_state_once = []
      @on_state = []

      setup_db
    end

    def clear
      setup_db
    end

    def <<(s)
      process s
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
    end

    # Finish up
    def stop
      @pool.each do |thread|
        thread.join
      end
    end

    def stop!
      @pool.each do |thread|
        thread.kill
      end
    end
  end
end
