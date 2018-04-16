module Runbook
  module Steps
    def steps
      @steps ||= []
    end

    def step(title=nil, &block)
      Step.new(title).tap do |step|
        steps << step
        step.instance_eval(&block) if block
      end
    end
  end

  Runbook::Section.prepend(Steps)
end
