class UState::Query
  require 'set'

  class Node
    def indent(s, d = 1)
      ("  " * d) + s.gsub("\n", "\n" + ("  " * d))
    end

    def inspect_helper(*kids)
      "#{self.class}\n#{indent kids.map { |k| k.inspect }.join("\n")}"
    end

    def inspect
      inspect_helper
    end
    
    def mass
      1
    end
  end
end
