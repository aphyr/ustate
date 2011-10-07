class UState::Query
  class Less < Node
    include Binarity
    
    def ===(state)
      x = state.send(@a) and x < @b
    end
  end
end
