class UState::Query
  class Or
    def initialize(a,b)
      @a = a
      @b = b
    end

    def ===(state)
      @a === state or @b === state
    end
  end
end
