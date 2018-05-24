module Runbook::Statements
  class Ask < Runbook::Statement
    attr_reader :prompt, :into, :default

    def initialize(prompt, into:, default: nil)
      @prompt = prompt
      @into = into
      @default = default
    end
  end
end
