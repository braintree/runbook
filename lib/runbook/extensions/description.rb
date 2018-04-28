module Runbook::Extensions
  module Description
    module DSL
      def description(msg)
        Runbook::Statements::Description.new(msg).tap do |desc|
          parent.items << desc
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Description::DSL)
  Runbook::Entities::Section::DSL.prepend(Description::DSL)
end
