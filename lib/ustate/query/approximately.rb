class UState::Query
  class Approximately < Node
    include Binarity
    
    def initialize(field, value)
      @a = field
      @b = case value
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
      @b === state.send(@a) 
    end
  end
end
