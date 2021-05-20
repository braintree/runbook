module Runbook::Extensions
  module Statements
    module DSL
      ruby2_keywords def method_missing(name, *args, &block)
        if (klass = Statements::DSL._statement_class(name))
          klass.new(*args, &block).tap do |statement|
            parent.add(statement)

            if statement.respond_to?(:into)
              Runbook.runtime_methods << statement.into
            end
          end
        else
          super
        end
      end

      def respond_to?(name, include_private = false)
        !!(Statements::DSL._statement_class(name) || super)
      end

      def self._statement_class(name)
        "Runbook::Statements::#{name.to_s.camelize}".constantize
      rescue NameError
      end
    end
  end

  Runbook::Entities::Setup::DSL.prepend(Statements::DSL)
  Runbook::Entities::Step::DSL.prepend(Statements::DSL)
end
