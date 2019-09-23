module Runbook::Statements
  class Ask < Runbook::Statement
    attr_reader :prompt, :into, :default, :echo

    def initialize(prompt, into:, default: nil, echo: true)
      @prompt = prompt
      @into = into
      @default = default
      @echo = echo
    end
  end
end
