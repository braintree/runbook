module Runbook::Extensions
  module Steps
    def step(title=nil, &block)
      Runbook::Entities::Step.new(title).tap do |step|
        items << step
        step.instance_eval(&block) if block
      end
    end
  end

  Runbook::Entities::Section.prepend(Steps)
end
