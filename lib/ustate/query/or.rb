class UState::Query
  class Or < Node
    def initialize(a,b)
      @a = a
      @b = b
    end

    def ===(state)
      @a === state or @b === state
    end

    def inspect
      inspect_helper @a, @b
    end
  end
end
