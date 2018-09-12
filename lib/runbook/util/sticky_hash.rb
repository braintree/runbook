module Runbook::Util
  class StickyHash < Hash
    def [](key)
      value = super
      value.is_a?(Glue) ? value.val : value
    end

    def []=(key, value)
      assoc = self.assoc(key)
      if assoc.nil? || ! assoc[1].is_a?(Glue)
        super
      else
        assoc[1].val = value
      end
    end
  end

  class Glue
    attr_accessor :val

    def initialize(val)
      @val = val
    end
  end
end

