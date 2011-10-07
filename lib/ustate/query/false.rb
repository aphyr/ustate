class UState::Query
  class False < Node
    def ==(other)
      other.kind_of? False
    end

    def ===(state)
      false
    end

    def to_s
      false
    end
  end
end
