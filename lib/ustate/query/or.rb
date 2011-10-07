class UState::Query
  class Or < Node
    include Narity
    
    def ===(state)
      @as.any? do |a|
        a === state
      end
    end
  end
end
