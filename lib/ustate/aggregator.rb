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

      start
    end

    # Combines states matching query with State.average
    def average(query, init)
      fold query do |states|
        State.average states, init
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
          interval = (@interval / @folds.size) rescue @interval
          @folds.each do |f, query|
            if combined = f[@index.query(Query.new(string: query))]
              @index << combined
            end
            sleep interval
          end
        end
      end
    end

    # Combines states matching query with State.sum
    def sum(query, init)
      fold query do |states|
        State.sum states, init
      end
    end
  end
end
