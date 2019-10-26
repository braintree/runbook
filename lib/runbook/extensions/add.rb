module Runbook::Extensions
  module Add
    module DSL
      def add(entity)
        parent.add(entity)
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Add::DSL)
  Runbook::Entities::Section::DSL.prepend(Add::DSL)
  Runbook::Entities::Setup::DSL.prepend(Add::DSL)
  Runbook::Entities::Step::DSL.prepend(Add::DSL)
end
