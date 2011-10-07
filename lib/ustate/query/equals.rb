class UState::Query
  class Equals < Node
    include Binarity
    def ===(state)
      state.send(@a) == @b
    end
  end
end
