module Runbook
  class Entity
    const_set(:DSL, Runbook::DSL.class)

    def self.inherited(child_class)
      child_class.const_set(:DSL, Runbook::DSL.class)
    end

    attr_reader :title, :dsl

    def initialize(title)
      @title = title
      @dsl = "#{self.class}::DSL".constantize.new(self)
    end

    def items
      @items ||= []
    end

    def method_missing(method, *args, &block)
      if dsl.respond_to?(method)
        dsl.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to?(name, include_private = false)
      !!(dsl.respond_to?(name) || super)
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

