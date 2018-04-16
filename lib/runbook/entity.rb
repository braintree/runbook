module Runbook
  class Entity
    attr_reader :title

    def initialize(title)
      @title = title
    end

    def items
      @items ||= []
    end
  end
end

