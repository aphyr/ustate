module UState
  class Server::Index
    # Combines state messages. Responds to queries for particular states.
    # Forwards messages to various receivers.
    # Inserts are NOT threadsafe.
    
    require 'sequel'

    THREADS = 1000
    BUFFER_SIZE = 10
    
    attr_reader :db, :queue 

    def initialize(opts = {})
      @db = Sequel.sqlite

      @threads = opts[:threads] || THREADS
      @pool = []

      setup_db
    end

    def setup_db
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

    def on_state_change(old, new)
    end

    def on_state(state)
    end

    def process(s)
      if current = @db[:states][host: s.host, service: s.service]
        # Update
        if current[:time] <= s.time
          if current[:state] != s.state
            on_state_change current, new
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
