class UState::Query
  class GreaterEqual
    def initialize(field, value)
      @field = field
      @value = value
    end
    
    def ===(state)
      x = state.send(@field) and x >= @value
    end
  end
end
