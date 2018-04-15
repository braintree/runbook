module Runbook
  class Section
    attr_reader :title

    def initialize(title)
      @title = title
    end

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
    prepend Steps
  end
end
