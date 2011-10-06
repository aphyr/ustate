class UState::Query
  class Not < Node
    def initialize(a)
      @a = a
    end

    def ===(state)
      not @a === state
    end

    def inspect
      inspect_helper @a
    end
  end
end
