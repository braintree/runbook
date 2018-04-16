module Runbook
  module Steps
    def step(title=nil, &block)
      Step.new(title).tap do |step|
        items << step
        step.instance_eval(&block) if block
      end
    end
  end

  Runbook::Section.prepend(Steps)
end
