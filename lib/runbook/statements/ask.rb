module Runbook::Statements
  class Ask
    attr_reader :prompt, :into

    def initialize(prompt, into:)
      @prompt = prompt
      @into = into
    end
  end
end
