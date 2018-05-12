module Runbook::Extensions
  module Set
    module DSL
      def set(key, value)
        parent.define_singleton_method(key) do
          value
        end
      end
    end
  end

  Runbook::Entities::Step::DSL.prepend(Set::DSL)
end
