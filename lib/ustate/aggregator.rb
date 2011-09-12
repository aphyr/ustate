class Aggregator
  # Combines states into one.
  
  def initialize(index)
    @index = index
    @index.on_state &method(:receive)

    @combinations = {}
  end

  # Combines states matching query with the given block. The block
  # receives an array of states which presently match.
  def combine(query, &block)
    parser = QueryStringParser.new
    q = parser.parse(query_string)
    unless q
      raise ArgumentError, "error parsing #{query_string.inspect} at line #{parser.failure_line}:#{parser.failure_column}: #{parser.failure_reason}"
    end
    q = q.query

    @combinations[block] = if existing = @combinations[block]
      Query::Or.new existing, q
    else
      q
    end
  end

  def receive(state)
    Thread.new do
      @combinations.each do |f, query|
        if query === state
          @index << f[query]
        end
      end
    end
  end
end
