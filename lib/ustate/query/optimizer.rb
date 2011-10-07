class UState::Query
  class Optimizer
    def self.[](node)
      new.optimize node
    end

    def initialize
    end

    # Remove true and false from and/or
    def collapse_boolean_literals(node)
      map node do |n|
        case n
        when And
          if n.children.any? do |c|
              False === c
          end
            puts "Collapsing and(false)"
            False.new
          else
            n.children.delete_if do |c|
              True === c
            end
            n
          end
        when Or
          if n.children.any? do |c|
              True === c
          end
            puts "Collapsing or(true)"
            True.new
          else
            n.children.delete_if do |c|
              False === c
            end
            n
          end
        else
          n
        end
      end
    end

    # Eliminate useless ands/ors
    def deref_ands_ors(node)
      map node do |n|
        case n
        when And
          case n.children.size
          when 0
            True.new
          when 1
            n.children.first
          else
            n
          end
        when Or
          case n.children.size
          when 0
            False.new
          when 1
            n.children.first
          else
            n
          end
        else
          n
        end
      end
    end

    def optimize(node)
      mass = node.mass + 1
      
      while node.mass < mass
        mass = node.mass
        node = transform node
      end

      node
    end

    def map(node, &block)
      # Transform node
      puts "Map #{node}"
      node = block[node] or raise RuntimeError "Mapped to nil"
      puts "Node is now #{node}"

      # Apply map to children
      if node.respond_to? :children
        puts "Node has children"
        node.children.map! do |n|
          map n, &block
        end
      end

      # Return node
      node
    end

    def traverse(node, &block)
      block[node]
      node.children.each do |child|
        traverse child, &block
      end
    end

    def transform(node)
      puts "Transform ------------\n#{node.inspect}"
      deref_ands_ors collapse_boolean_literals node
    end
  end
end
