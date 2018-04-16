module Runbook
  class Entity
    attr_reader :title

    def initialize(title)
      @title = title
    end

    def items
      @items ||= []
    end

    def render(view, string)
      view.render(self, string)
      items.each do |item|
        item.render(view, string)
      end
    end
  end
end

