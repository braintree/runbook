module Runbook
  class Entity
    attr_reader :title

    def initialize(title)
      @title = title
    end

    def items
      @items ||= []
    end

    def render(view, output)
      view.render_before(self, output)
      items.each do |item|
        item.render(view, output)
      end
      view.render_after(self, output)
    end
  end
end

