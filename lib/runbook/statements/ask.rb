module Runbook::Statements
  class Ask < Runbook::Statement
    attr_reader :prompt, :into

    def initialize(prompt, into:)
      @prompt = prompt
      @into = into
    end
  end
end
