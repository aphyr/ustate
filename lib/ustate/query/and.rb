class UState::Query
  class And
    def initialize(a,b)
      @a = a
      @b = b
    end

    def ===(state)
      @a === state and @b === state
    end
  end
end
