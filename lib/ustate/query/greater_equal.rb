class UState::Query
  class GreaterEqual < Node
    include Binarity
    
    def ===(state)
      x = state.send(@a) and x >= @b
    end
  end
end
