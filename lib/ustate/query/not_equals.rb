class UState::Query
  class NotEquals
    def initialize(field, value)
      @field = field
      @value = value
    end

    def ===(state)
      state.send(@field) != @value
    end
  end
end
