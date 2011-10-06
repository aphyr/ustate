class UState::Query
  class False < Node
    def initialize
    end

    def ===(state)
      false
    end
  end
end
