module Runbook::Statements
  class Description < Runbook::Statement
    attr_reader :msg

    def initialize(msg)
      @msg = msg
    end
  end
end

