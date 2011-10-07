class UState::Query
  class Not < Node
    attr_reader :a
    def initialize(a)
      @a = a
    end

    def ==(o)
      o.kind_of? Not and @a == o.a
    end

    def ===(state)
      not @a === state
    end

    def children
      [@a]
    end

    def children=(c)
      raise ArgumentError unless c.size == 1
    end

    def inspect
      inspect_helper @a
    end

    def mass
      1 + @a.mass
    end
  end
end
