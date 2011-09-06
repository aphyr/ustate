class UState::Query
  class Not
    def initialize(a)
      @a = a
    end

    def ===(state)
      not @a === state
    end
  end
end
