class UState::Query
  class Greater
    def initialize(field, value)
      @field = field
      @value = value
    end
    
    def ===(state)
      x = state.send(@field) and x > @value
    end
  end
end
