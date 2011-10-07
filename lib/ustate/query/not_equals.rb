class UState::Query
  class NotEquals < Node
    include Binarity

    def ===(state)
      state.send(@a) != @b
    end
  end
end
