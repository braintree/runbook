module Runbook::Extensions
  module Setup
    module DSL
      def setup(*tags, labels: {}, &block)
        Runbook::Entities::Setup.new(
          tags: tags,
          labels: labels,
        ).tap do |setup|
          parent.add(setup)
          setup.dsl.instance_eval(&block) if block
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Setup::DSL)
end
