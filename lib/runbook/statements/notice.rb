module Runbook::Statements
  class Notice
    attr_reader :msg

    def initialize(msg)
      @msg = msg
    end
  end
end

