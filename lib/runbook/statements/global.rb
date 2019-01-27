module Runbook::Statements
  class Global < Runbook::Statement
    attr_reader :globals

    def initialize(*globals)
      @globals = globals
    end
  end
end
