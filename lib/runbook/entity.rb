module Runbook
  class Entity
    include Runbook::Hooks::Invoker
    const_set(:DSL, Runbook::DSL.class)

    def self.inherited(child_class)
      child_class.const_set(:DSL, Runbook::DSL.class)
    end

    attr_accessor :parent
    attr_reader :title, :dsl

    def initialize(title, parent: nil)
      @title = title
      @parent = parent
      @dsl = "#{self.class}::DSL".constantize.new(self)
    end

    def add(item)
      items << item
      item.parent = self
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

    def render(view, output, metadata)
      invoke_with_hooks(view, self, output, metadata) do
        view.render(self, output, metadata)
        items.each_with_index do |item, index|
          new_metadata = _render_metadata(items, item, metadata, index)
          item.render(view, output, new_metadata)
        end
      end
    end

    def run(run, metadata)
      invoke_with_hooks(run, self, metadata) do
        run.execute(self, metadata)
        items.each_with_index do |item, index|
          new_metadata = _run_metadata(items, item, metadata, index)
          item.run(run, new_metadata)
        end
      end
    end

    def _render_metadata(items, item, metadata, index)
      index = items.select do |item|
        item.is_a?(Entity)
      end.index(item)

      metadata.merge(
        {
          depth: metadata[:depth] + 1,
          index: index,
        }
      )
    end

    def _run_metadata(items, item, metadata, index)
      pos_index = items.select do |item|
        item.is_a?(Entity)
      end.index(item)

      if pos_index
        if metadata[:position].empty?
          pos = "#{pos_index + 1}"
        else
          pos = "#{metadata[:position]}.#{pos_index + 1}"
        end
      else
        pos = metadata[:position]
      end

      metadata.merge(
        {
          depth: metadata[:depth] + 1,
          index: index,
          position: pos,
        }
      )
    end
  end
end
