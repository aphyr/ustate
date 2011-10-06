module UState
  class Reaper
    # The reaper deletes old states from an index.
    
    # By default, states die after
    DEFAULT = 1000
    # By default, scans for old states every
    INTERVAL = 10

    attr_reader :default
    attr_accessor :index
    attr_accessor :interval
    attr_accessor :targets

    def initialize(index, opts = {})
      @index = index
      @interval = opts[:interval] || INTERVAL
      @server = opts[:server]
      @targets = {}
      @lock = Mutex.new
      @compiled_targets = {}
      self.default = opts[:default] || DEFAULT

      start
    end

    # Transform targets into disjoint queries, ordered by age.
    # This is kinda ugly; should do write an AST optimizer with boolean 
    # minimization if anyone starts using this feature heavily.
    def compile
      @lock.synchronize do
        @compiled_targets = {}
        
        ordered = @targets.sort do |a,b|
          # The states with the longest lifetimes must be excluded from
          # all the younger checks. Nil = +inf.
          if b[1].nil?
            1
          elsif a[1].nil?
            -1
          else
            b[1] <=> a[1]
          end
        end
        
        excluded = ordered.inject(nil) do |exclude, pair|
          # Build up a set of all queries which should last *longer* than us.
          query, age = pair
          if exclude
            if age
              @compiled_targets["(#{query}) and not (#{exclude})"] = age
            end
            "(#{query}) or (#{exclude})"
          else
            if age
              @compiled_targets[query] = age
            end
            query
          end
        end

        # Add default
        if @default
          q = if excluded
                "not (#{excluded})"
              else
                "true"
              end
          @compiled_targets[q] = @default
        end
      end
    end
    
    def default=(d)
      @default = d
      compile
    end

    # Delete states matching query
    def delete(query)
      @index.query(Query.new(string: query)).each do |state|
        @index.on_state_change(
          state,
          State.new(
            host: state.host,
            service: state.service,
            state: 'unknown',
            description: "ustate has not heard from this service since #{Time.at(state.time)}",
            time: Time.now.to_i
          )
        )
        @index.delete state
      end
    end

    # Reap states matching query after age seconds.
    #
    # The reaper is gentle; it will give any state specified to reap() the
    # maximum possible time to live.
    def reap(query, age)
      reap! query, age
      compile
    end

    def reap!(query, age)
      @targets[query] = age
    end

    def start
      @runner = Thread.new do
        loop do
          begin
            @lock.synchronize do
              @compiled_targets.each do |query, age|
                delete "(#{query}) and time < #{(Time.now - age).to_i}"
              end
            end
          rescue Exception => e
            @server.log.warn e
          end
          sleep @interval
        end
      end
    end
  end
end
