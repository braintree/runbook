module Runbook
  class Entity
    attr_reader :title

    def initialize(title)
      @title = title
    end

    def items
      @items ||= []
    end

    def render(view, output, metadata={depth: 1, index: 0, parent: nil})
      view.render(self, output, metadata)
      items.each_with_index do |item, index|
        item.render(view, output, _render_metadata(metadata, index))
      end
    end

    def _render_metadata(metadata, index)
      {
        depth: metadata[:depth] + 1,
        index: index,
        parent: self,
      }
    end
  end
end

