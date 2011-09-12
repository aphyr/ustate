module UState
  class Query
    include Beefcake::Message
  
    optional :string, :string, 1

    # Converts a Query or string to a query AST.
    def self.query(q)
      case q
      when String
        parser = QueryStringParser.new
        q = parser.parse(q)
        unless q
          raise ArgumentError, "error parsing #{query_string.inspect} at line #{parser.failure_line}:#{parser.failure_column}: #{parser.failure_reason}"
        end
        q.query
      when Query
        query q.string
      else
        raise ArgumentError, "don't know what to do with #{q.class} #{q.inspect}"
      end
    end
  end 
end
