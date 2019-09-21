module Runbook::Extensions
  module Steps
    module DSL
      def step(title=nil, &block)
        Runbook::Entities::Step.new(title).tap do |step|
          parent.add(step)
          step.dsl.instance_eval(&block) if block
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Steps::DSL)
  Runbook::Entities::Section::DSL.prepend(Steps::DSL)
end
