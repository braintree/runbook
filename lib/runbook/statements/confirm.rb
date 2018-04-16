module Runbook::Statements
  class Confirm < Runbook::Statement
    attr_reader :prompt

    def initialize(prompt)
      @prompt = prompt
    end
  end
end

