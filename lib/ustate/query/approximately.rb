class UState::Query
  class Approximately < Node
    def initialize(field, value)
      @field = field
      @value = case value
        when String
          r = value.chars.inject('') do |r, c|
            if c == '%'
              r << '.*'
            else
              r << Regexp.escape(c)
            end
          end
          /^#{r}$/
        else
          value
        end
    end

    def ===(state)
      @value === state.send(@field) 
    end

    def inspect
      inspect_helper @field, @value
    end
  end
end
