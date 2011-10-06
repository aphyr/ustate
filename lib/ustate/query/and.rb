class UState::Query
  class And < Node
    def initialize(a,b)
      @a = a
      @b = b
    end

    def ===(state)
      @a === state and @b === state
    end

    def inspect
      inspect_helper @a, @b
    end
  end
end
