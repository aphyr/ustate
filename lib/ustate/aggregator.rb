module UState
  class Aggregator
    # Combines states periodically.

    INTERVAL = 1

    attr_accessor :interval
    attr_accessor :folds
    def initialize(index, opts = {})
      @index = index

      @folds = {}
      @interval = opts[:interval] || INTERVAL
      @server = opts[:server]

      start
    end

    # Combines states matching query with State.average
    def average(query, *a)
      fold query do |states|
        State.average states, *a
      end
    end
    
    # Average states with the same service across varying hosts.
    # Useful when you don't know the exact services you'd like to fold.
    # The resulting host for each folded state will be nil.
    def average_over_hosts(query)
      fold query do |states|
        State.partition(states, :service).values.map do |slice|
          State.sum slice, {host: nil}
        end
      end
    end

    # Combines states matching query with the given block. The block
    # receives an array of states which presently match.
    # 
    # Example:
    #   fold 'service = "api % reqs/sec"' do |states|
    #     states.inject(State.new(service: 'api reqs/sec')) do |combined, state|
    #       combined.metric_f += state.metric_f
    #       combined
    #     end
    #   end
    def fold(query, &block)
      @folds[block] = if existing = @folds[block]
        "(#{existing}) or (#{q})"
      else
        query
      end
    end

    # Polls index for states matching each fold, applies fold, and inserts into
    # index.
    def start
      @runner = Thread.new do
        loop do
          begin
            interval = (@interval.to_f / @folds.size) rescue @interval
            @folds.each do |f, query|
              matching = @index.query(Query.new(string: query))
              unless matching.empty?
                case combined = f[matching]
                when State
                  @index << combined
                when Array
                  combined.each do |s|
                    @index << s
                  end
                end
              end
              sleep interval
            end
          rescue Exception => e
            @server.log.error e
            sleep 1
          end
        end
      end
    end

    # Combines states matching query with State.sum
    def sum(query, *a)
      fold query do |states|
        State.sum states, *a
      end
    end

    # Sum states with the same service across varying hosts.
    # Useful when you don't know the exact services you'd like to fold.
    def sum_over_hosts(query)
      fold query do |states|
        State.partition(states, :service).values.map do |slice|
          State.sum slice, {host: nil}
        end
      end
    end
  end
end
