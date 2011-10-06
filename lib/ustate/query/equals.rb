class UState::Query
  class Equals < Node
    def initialize(field, value)
      @field = field
      @value = value
    end
    
    def ===(state)
      state.send(@field) == @value
    end

    def inspect
      inspect_helper @field, @value
    end
  end
end
