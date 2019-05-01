module Runbook
  class Node
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
  end
end
