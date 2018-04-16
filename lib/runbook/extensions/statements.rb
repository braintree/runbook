module Runbook::Extensions
  module Statements
    def method_missing(name, *args, &block)
      if (klass = Statements._statement_class(name))
        klass.new(*args, &block).tap do |statement|
          items << statement
        end
      else
        super
      end
    end

    def respond_to?(name, include_private = false)
      !!(Statements._statement_class(name) || super)
    end

    def self._statement_class(name)
      "Runbook::Statements::#{name.to_s.camelize}".constantize
    rescue NameError
    end
  end

  Runbook::Step.prepend(Statements)
end
