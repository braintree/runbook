module Runbook::Statements
  class Note < Runbook::Statement
    attr_reader :msg

    def initialize(msg)
      @msg = msg
    end
  end
end

