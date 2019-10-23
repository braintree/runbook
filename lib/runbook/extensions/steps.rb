module Runbook::Extensions
  module Steps
    module DSL
      def step(title=nil, *tags, labels: {}, &block)
        if title.is_a?(Symbol)
          tags.unshift(title)
          title = nil
        end

        Runbook::Entities::Step.new(
          title,
          tags: tags,
          labels: labels,
        ).tap do |step|
          parent.add(step)
          step.dsl.instance_eval(&block) if block
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Steps::DSL)
  Runbook::Entities::Section::DSL.prepend(Steps::DSL)
end
