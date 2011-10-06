class UState::Query
  class Greater < Node
    def initialize(field, value)
      @field = field
      @value = value
    end
    
    def ===(state)
      x = state.send(@field) and x > @value
    end

    def inspect
      inspect_helper @field, @value
    end
  end
end
