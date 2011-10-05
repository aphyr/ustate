# Autogenerated from a Treetop grammar. Edits may be lost.


module UState
  module QueryString
    include Treetop::Runtime

    def root
      @root ||= :or
    end

    module Or0
      def space1
        elements[0]
      end

      def space2
        elements[2]
      end

      def and
        elements[3]
      end
    end

    module Or1
      def first
        elements[0]
      end

      def rest
        elements[1]
      end
    end

    module Or2
      def query
        rest.elements.map { |x| x.and }.inject(first.query) do |a, sub|
          Query::Or.new a, sub.query
        end
      end

      def sql
        rest.elements.map { |x| x.and }.
          inject(first.sql) do |a, sub|
            a | sub.sql
          end
      end
    end

    def _nt_or
      start_index = index
      if node_cache[:or].has_key?(index)
        cached = node_cache[:or][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_and
      s0 << r1
      if r1
        s2, i2 = [], index
        loop do
          i3, s3 = index, []
          r4 = _nt_space
          s3 << r4
          if r4
            if has_terminal?('or', false, index)
              r5 = instantiate_node(SyntaxNode,input, index...(index + 2))
              @index += 2
            else
              terminal_parse_failure('or')
              r5 = nil
            end
            s3 << r5
            if r5
              r6 = _nt_space
              s3 << r6
              if r6
                r7 = _nt_and
                s3 << r7
              end
            end
          end
          if s3.last
            r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
            r3.extend(Or0)
          else
            @index = i3
            r3 = nil
          end
          if r3
            s2 << r3
          else
            break
          end
        end
        r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
        s0 << r2
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Or1)
        r0.extend(Or2)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:or][start_index] = r0

      r0
    end

    module And0
      def space1
        elements[0]
      end

      def space2
        elements[2]
      end

      def primary
        elements[3]
      end
    end

    module And1
      def first
        elements[0]
      end

      def rest
        elements[1]
      end
    end

    module And2
      def query
        rest.elements.map { |x| x.primary }.inject(first.query) do |a, sub|
          Query::And.new a, sub.query
        end
      end

      def sql
        rest.elements.map { |x| x.primary }.
          inject(first.sql) do |a, sub|
            a & sub.sql
          end
      end
    end

    def _nt_and
      start_index = index
      if node_cache[:and].has_key?(index)
        cached = node_cache[:and][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_primary
      s0 << r1
      if r1
        s2, i2 = [], index
        loop do
          i3, s3 = index, []
          r4 = _nt_space
          s3 << r4
          if r4
            if has_terminal?('and', false, index)
              r5 = instantiate_node(SyntaxNode,input, index...(index + 3))
              @index += 3
            else
              terminal_parse_failure('and')
              r5 = nil
            end
            s3 << r5
            if r5
              r6 = _nt_space
              s3 << r6
              if r6
                r7 = _nt_primary
                s3 << r7
              end
            end
          end
          if s3.last
            r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
            r3.extend(And0)
          else
            @index = i3
            r3 = nil
          end
          if r3
            s2 << r3
          else
            break
          end
        end
        r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
        s0 << r2
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(And1)
        r0.extend(And2)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:and][start_index] = r0

      r0
    end

    module Primary0
      def x
        elements[2]
      end

    end

    module Primary1
      def query
        x.query
      end

      def sql
        x.sql
      end
    end

    def _nt_primary
      start_index = index
      if node_cache[:primary].has_key?(index)
        cached = node_cache[:primary][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0 = index
      i1, s1 = index, []
      if has_terminal?('(', false, index)
        r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('(')
        r2 = nil
      end
      s1 << r2
      if r2
        r4 = _nt_space
        if r4
          r3 = r4
        else
          r3 = instantiate_node(SyntaxNode,input, index...index)
        end
        s1 << r3
        if r3
          r5 = _nt_or
          s1 << r5
          if r5
            r7 = _nt_space
            if r7
              r6 = r7
            else
              r6 = instantiate_node(SyntaxNode,input, index...index)
            end
            s1 << r6
            if r6
              if has_terminal?(')', false, index)
                r8 = instantiate_node(SyntaxNode,input, index...(index + 1))
                @index += 1
              else
                terminal_parse_failure(')')
                r8 = nil
              end
              s1 << r8
            end
          end
        end
      end
      if s1.last
        r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
        r1.extend(Primary0)
        r1.extend(Primary1)
      else
        @index = i1
        r1 = nil
      end
      if r1
        r0 = r1
      else
        r9 = _nt_predicate
        if r9
          r0 = r9
        else
          @index = i0
          r0 = nil
        end
      end

      node_cache[:primary][start_index] = r0

      r0
    end

    def _nt_predicate
      start_index = index
      if node_cache[:predicate].has_key?(index)
        cached = node_cache[:predicate][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0 = index
      r1 = _nt_less_equal
      if r1
        r0 = r1
      else
        r2 = _nt_less
        if r2
          r0 = r2
        else
          r3 = _nt_greater_equal
          if r3
            r0 = r3
          else
            r4 = _nt_greater
            if r4
              r0 = r4
            else
              r5 = _nt_equals
              if r5
                r0 = r5
              else
                r6 = _nt_not_equals
                if r6
                  r0 = r6
                else
                  r7 = _nt_approximately
                  if r7
                    r0 = r7
                  else
                    @index = i0
                    r0 = nil
                  end
                end
              end
            end
          end
        end
      end

      node_cache[:predicate][start_index] = r0

      r0
    end

    module Approximately0
      def field
        elements[0]
      end

      def string
        elements[4]
      end
    end

    module Approximately1
      def query
        Query::Approximately.new field.sql, string.sql
      end

      def sql
        Sequel::SQL::StringExpression.like field.sql, string.sql
      end
    end

    def _nt_approximately
      start_index = index
      if node_cache[:approximately].has_key?(index)
        cached = node_cache[:approximately][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_field
      s0 << r1
      if r1
        r3 = _nt_space
        if r3
          r2 = r3
        else
          r2 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r2
        if r2
          if has_terminal?('=~', false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 2))
            @index += 2
          else
            terminal_parse_failure('=~')
            r4 = nil
          end
          s0 << r4
          if r4
            r6 = _nt_space
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
            if r5
              r7 = _nt_string
              s0 << r7
            end
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Approximately0)
        r0.extend(Approximately1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:approximately][start_index] = r0

      r0
    end

    module LessEqual0
      def field
        elements[0]
      end

      def value
        elements[4]
      end
    end

    module LessEqual1
      def query
        Query::LessEqual.new field.sql, value.sql
      end

      def sql
        Sequel::SQL::BooleanExpression.new(:<=, field.sql, value.sql)
      end
    end

    def _nt_less_equal
      start_index = index
      if node_cache[:less_equal].has_key?(index)
        cached = node_cache[:less_equal][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_field
      s0 << r1
      if r1
        r3 = _nt_space
        if r3
          r2 = r3
        else
          r2 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r2
        if r2
          if has_terminal?('<=', false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 2))
            @index += 2
          else
            terminal_parse_failure('<=')
            r4 = nil
          end
          s0 << r4
          if r4
            r6 = _nt_space
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
            if r5
              r7 = _nt_value
              s0 << r7
            end
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(LessEqual0)
        r0.extend(LessEqual1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:less_equal][start_index] = r0

      r0
    end

    module Less0
      def field
        elements[0]
      end

      def value
        elements[4]
      end
    end

    module Less1
      def query
        Query::Less.new field.sql, value.sql
      end

      def sql
        Sequel::SQL::BooleanExpression.new(:<, field.sql, value.sql)
      end
    end

    def _nt_less
      start_index = index
      if node_cache[:less].has_key?(index)
        cached = node_cache[:less][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_field
      s0 << r1
      if r1
        r3 = _nt_space
        if r3
          r2 = r3
        else
          r2 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r2
        if r2
          if has_terminal?('<', false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure('<')
            r4 = nil
          end
          s0 << r4
          if r4
            r6 = _nt_space
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
            if r5
              r7 = _nt_value
              s0 << r7
            end
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Less0)
        r0.extend(Less1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:less][start_index] = r0

      r0
    end

    module GreaterEqual0
      def field
        elements[0]
      end

      def value
        elements[4]
      end
    end

    module GreaterEqual1
      def query
        Query::GreaterEqual.new field.sql, value.sql
      end

      def sql
        Sequel::SQL::BooleanExpression.new(:>=, field.sql, value.sql)
      end
    end

    def _nt_greater_equal
      start_index = index
      if node_cache[:greater_equal].has_key?(index)
        cached = node_cache[:greater_equal][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_field
      s0 << r1
      if r1
        r3 = _nt_space
        if r3
          r2 = r3
        else
          r2 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r2
        if r2
          if has_terminal?('>=', false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 2))
            @index += 2
          else
            terminal_parse_failure('>=')
            r4 = nil
          end
          s0 << r4
          if r4
            r6 = _nt_space
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
            if r5
              r7 = _nt_value
              s0 << r7
            end
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(GreaterEqual0)
        r0.extend(GreaterEqual1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:greater_equal][start_index] = r0

      r0
    end

    module Greater0
      def field
        elements[0]
      end

      def value
        elements[4]
      end
    end

    module Greater1
      def query
        Query::Greater.new field.sql, value.sql
      end

      def sql
        Sequel::SQL::BooleanExpression.new(:>, field.sql, value.sql)
      end
    end

    def _nt_greater
      start_index = index
      if node_cache[:greater].has_key?(index)
        cached = node_cache[:greater][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_field
      s0 << r1
      if r1
        r3 = _nt_space
        if r3
          r2 = r3
        else
          r2 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r2
        if r2
          if has_terminal?('>', false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure('>')
            r4 = nil
          end
          s0 << r4
          if r4
            r6 = _nt_space
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
            if r5
              r7 = _nt_value
              s0 << r7
            end
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Greater0)
        r0.extend(Greater1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:greater][start_index] = r0

      r0
    end

    module NotEquals0
      def field
        elements[0]
      end

      def value
        elements[4]
      end
    end

    module NotEquals1
      def query
        Query::NotEquals.new field.sql, value.sql
      end
      
      def sql
        Sequel::SQL::BooleanExpression.from_value_pairs({field.sql => value.sql}, :AND, true)
      end
    end

    def _nt_not_equals
      start_index = index
      if node_cache[:not_equals].has_key?(index)
        cached = node_cache[:not_equals][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_field
      s0 << r1
      if r1
        r3 = _nt_space
        if r3
          r2 = r3
        else
          r2 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r2
        if r2
          if has_terminal?('!=', false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 2))
            @index += 2
          else
            terminal_parse_failure('!=')
            r4 = nil
          end
          s0 << r4
          if r4
            r6 = _nt_space
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
            if r5
              r7 = _nt_value
              s0 << r7
            end
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(NotEquals0)
        r0.extend(NotEquals1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:not_equals][start_index] = r0

      r0
    end

    module Equals0
      def field
        elements[0]
      end

      def value
        elements[4]
      end
    end

    module Equals1
      def query
        Query::Equals.new field.sql, value.sql
      end

      def sql
        Sequel::SQL::BooleanExpression.from_value_pairs field.sql => value.sql
      end
    end

    def _nt_equals
      start_index = index
      if node_cache[:equals].has_key?(index)
        cached = node_cache[:equals][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      r1 = _nt_field
      s0 << r1
      if r1
        r3 = _nt_space
        if r3
          r2 = r3
        else
          r2 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r2
        if r2
          i4 = index
          if has_terminal?('==', false, index)
            r5 = instantiate_node(SyntaxNode,input, index...(index + 2))
            @index += 2
          else
            terminal_parse_failure('==')
            r5 = nil
          end
          if r5
            r4 = r5
          else
            if has_terminal?('=', false, index)
              r6 = instantiate_node(SyntaxNode,input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure('=')
              r6 = nil
            end
            if r6
              r4 = r6
            else
              @index = i4
              r4 = nil
            end
          end
          s0 << r4
          if r4
            r8 = _nt_space
            if r8
              r7 = r8
            else
              r7 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r7
            if r7
              r9 = _nt_value
              s0 << r9
            end
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Equals0)
        r0.extend(Equals1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:equals][start_index] = r0

      r0
    end

    def _nt_value
      start_index = index
      if node_cache[:value].has_key?(index)
        cached = node_cache[:value][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0 = index
      r1 = _nt_double_quoted_string
      if r1
        r0 = r1
      else
        r2 = _nt_float
        if r2
          r0 = r2
        else
          r3 = _nt_integer
          if r3
            r0 = r3
          else
            r4 = _nt_null
            if r4
              r0 = r4
            else
              @index = i0
              r0 = nil
            end
          end
        end
      end

      node_cache[:value][start_index] = r0

      r0
    end

    module Integer0
    end

    module Integer1
      def ruby_value
        Integer(text_value)
      end
      alias sql ruby_value
    end

    def _nt_integer
      start_index = index
      if node_cache[:integer].has_key?(index)
        cached = node_cache[:integer][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      if has_terminal?('-', false, index)
        r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('-')
        r2 = nil
      end
      if r2
        r1 = r2
      else
        r1 = instantiate_node(SyntaxNode,input, index...index)
      end
      s0 << r1
      if r1
        s3, i3 = [], index
        loop do
          if has_terminal?('\G[0-9]', true, index)
            r4 = true
            @index += 1
          else
            r4 = nil
          end
          if r4
            s3 << r4
          else
            break
          end
        end
        if s3.empty?
          @index = i3
          r3 = nil
        else
          r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
        end
        s0 << r3
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Integer0)
        r0.extend(Integer1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:integer][start_index] = r0

      r0
    end

    module Float0
    end

    module Float1
      def ruby_value
        Float(text_value)
      end

      alias sql ruby_value
    end

    def _nt_float
      start_index = index
      if node_cache[:float].has_key?(index)
        cached = node_cache[:float][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      if has_terminal?('-', false, index)
        r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('-')
        r2 = nil
      end
      if r2
        r1 = r2
      else
        r1 = instantiate_node(SyntaxNode,input, index...index)
      end
      s0 << r1
      if r1
        s3, i3 = [], index
        loop do
          if has_terminal?('\G[0-9]', true, index)
            r4 = true
            @index += 1
          else
            r4 = nil
          end
          if r4
            s3 << r4
          else
            break
          end
        end
        if s3.empty?
          @index = i3
          r3 = nil
        else
          r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
        end
        s0 << r3
        if r3
          if has_terminal?('.', false, index)
            r5 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure('.')
            r5 = nil
          end
          s0 << r5
          if r5
            s6, i6 = [], index
            loop do
              if has_terminal?('\G[0-9]', true, index)
                r7 = true
                @index += 1
              else
                r7 = nil
              end
              if r7
                s6 << r7
              else
                break
              end
            end
            if s6.empty?
              @index = i6
              r6 = nil
            else
              r6 = instantiate_node(SyntaxNode,input, i6...index, s6)
            end
            s0 << r6
          end
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Float0)
        r0.extend(Float1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:float][start_index] = r0

      r0
    end

    module Field0
      def sql
        text_value.to_sym
      end
    end

    def _nt_field
      start_index = index
      if node_cache[:field].has_key?(index)
        cached = node_cache[:field][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0 = index
      if has_terminal?("state", false, index)
        r1 = instantiate_node(SyntaxNode,input, index...(index + 5))
        @index += 5
      else
        terminal_parse_failure("state")
        r1 = nil
      end
      if r1
        r0 = r1
        r0.extend(Field0)
      else
        if has_terminal?("host", false, index)
          r2 = instantiate_node(SyntaxNode,input, index...(index + 4))
          @index += 4
        else
          terminal_parse_failure("host")
          r2 = nil
        end
        if r2
          r0 = r2
          r0.extend(Field0)
        else
          if has_terminal?("service", false, index)
            r3 = instantiate_node(SyntaxNode,input, index...(index + 7))
            @index += 7
          else
            terminal_parse_failure("service")
            r3 = nil
          end
          if r3
            r0 = r3
            r0.extend(Field0)
          else
            if has_terminal?("description", false, index)
              r4 = instantiate_node(SyntaxNode,input, index...(index + 11))
              @index += 11
            else
              terminal_parse_failure("description")
              r4 = nil
            end
            if r4
              r0 = r4
              r0.extend(Field0)
            else
              if has_terminal?("metric_f", false, index)
                r5 = instantiate_node(SyntaxNode,input, index...(index + 8))
                @index += 8
              else
                terminal_parse_failure("metric_f")
                r5 = nil
              end
              if r5
                r0 = r5
                r0.extend(Field0)
              else
                if has_terminal?("time", false, index)
                  r6 = instantiate_node(SyntaxNode,input, index...(index + 4))
                  @index += 4
                else
                  terminal_parse_failure("time")
                  r6 = nil
                end
                if r6
                  r0 = r6
                  r0.extend(Field0)
                else
                  @index = i0
                  r0 = nil
                end
              end
            end
          end
        end
      end

      node_cache[:field][start_index] = r0

      r0
    end

    def _nt_string
      start_index = index
      if node_cache[:string].has_key?(index)
        cached = node_cache[:string][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      r0 = _nt_double_quoted_string

      node_cache[:string][start_index] = r0

      r0
    end

    module DoubleQuotedString0
    end

    module DoubleQuotedString1
    end

    module DoubleQuotedString2
      def ruby_value
        text_value[1..-2].gsub('\"', '"')
      end
      alias sql ruby_value
    end

    def _nt_double_quoted_string
      start_index = index
      if node_cache[:double_quoted_string].has_key?(index)
        cached = node_cache[:double_quoted_string][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0, s0 = index, []
      if has_terminal?('"', false, index)
        r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('"')
        r1 = nil
      end
      s0 << r1
      if r1
        s2, i2 = [], index
        loop do
          i3 = index
          i4, s4 = index, []
          i5 = index
          if has_terminal?('"', false, index)
            r6 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure('"')
            r6 = nil
          end
          if r6
            r5 = nil
          else
            @index = i5
            r5 = instantiate_node(SyntaxNode,input, index...index)
          end
          s4 << r5
          if r5
            if index < input_length
              r7 = instantiate_node(SyntaxNode,input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure("any character")
              r7 = nil
            end
            s4 << r7
          end
          if s4.last
            r4 = instantiate_node(SyntaxNode,input, i4...index, s4)
            r4.extend(DoubleQuotedString0)
          else
            @index = i4
            r4 = nil
          end
          if r4
            r3 = r4
          else
            if has_terminal?('\"', false, index)
              r8 = instantiate_node(SyntaxNode,input, index...(index + 2))
              @index += 2
            else
              terminal_parse_failure('\"')
              r8 = nil
            end
            if r8
              r3 = r8
            else
              @index = i3
              r3 = nil
            end
          end
          if r3
            s2 << r3
          else
            break
          end
        end
        r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
        s0 << r2
        if r2
          if has_terminal?('"', false, index)
            r9 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure('"')
            r9 = nil
          end
          s0 << r9
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(DoubleQuotedString1)
        r0.extend(DoubleQuotedString2)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:double_quoted_string][start_index] = r0

      r0
    end

    module Null0
      def ruby_value
        nil
      end
      alias sql ruby_value
    end

    def _nt_null
      start_index = index
      if node_cache[:null].has_key?(index)
        cached = node_cache[:null][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0 = index
      if has_terminal?('null', false, index)
        r1 = instantiate_node(SyntaxNode,input, index...(index + 4))
        @index += 4
      else
        terminal_parse_failure('null')
        r1 = nil
      end
      if r1
        r0 = r1
        r0.extend(Null0)
      else
        if has_terminal?('nil', false, index)
          r2 = instantiate_node(SyntaxNode,input, index...(index + 3))
          @index += 3
        else
          terminal_parse_failure('nil')
          r2 = nil
        end
        if r2
          r0 = r2
          r0.extend(Null0)
        else
          @index = i0
          r0 = nil
        end
      end

      node_cache[:null][start_index] = r0

      r0
    end

    def _nt_space
      start_index = index
      if node_cache[:space].has_key?(index)
        cached = node_cache[:space][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      s0, i0 = [], index
      loop do
        if has_terminal?('\G[\\s]', true, index)
          r1 = true
          @index += 1
        else
          r1 = nil
        end
        if r1
          s0 << r1
        else
          break
        end
      end
      if s0.empty?
        @index = i0
        r0 = nil
      else
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      end

      node_cache[:space][start_index] = r0

      r0
    end

  end

  class QueryStringParser < Treetop::Runtime::CompiledParser
    include QueryString
  end

end
