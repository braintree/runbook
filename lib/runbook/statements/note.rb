module Runbook::Statements
  class Note
    attr_reader :msg

    def initialize(msg)
      @msg = msg
    end
  end
end

