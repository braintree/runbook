module Runbook
  class Node
    attr_accessor :parent

    def initialize
      raise "Should not be initialized"
    end

    def dynamic!
      @dynamic = true
    end

    def visited!
      @visited = true
    end

    def dynamic?
      @dynamic
    end

    def visited?
      @visited
    end

    def parent_entity
      node = self
      while(node && !node.is_a?(Runbook::Entity))
        node = node.parent
      end
      node
    end
  end
end
