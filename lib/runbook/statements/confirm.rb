module Runbook::Statements
  class Confirm
    attr_reader :prompt

    def initialize(prompt)
      @prompt = prompt
    end
  end
end

