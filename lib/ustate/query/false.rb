class UState::Query
  class False
    def initialize
    end

    def ===(state)
      false
    end
  end
end
