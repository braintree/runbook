module Runbook
  module DSL
    def self.class(*modules)
      Class.new do
        attr_reader :parent

        def initialize(parent)
          @parent = parent
        end

        modules.each do |mod|
          prepend mod
        end
      end
    end
  end
end
