class UState::Query
  class True < Node
    def initialize
    end

    def ===(state)
      true
    end
  end
end
