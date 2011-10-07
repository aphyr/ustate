class UState::Query
  class And < Node
    include Narity

    def ===(state)
      as.all? do |a|
        a === state
      end
    end
  end
end
