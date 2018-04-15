module Runbook::Statements
  class Wait
    attr_reader :time

    def initialize(time)
      @time = time
    end
  end
end

