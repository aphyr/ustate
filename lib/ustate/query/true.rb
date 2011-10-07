class UState::Query
  class True < Node
    def ==(o)
      o.kind_of? True
    end

    def ===(state)
      true
    end

    def to_s
      true
    end
  end
end
