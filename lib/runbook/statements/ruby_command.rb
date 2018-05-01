module Runbook::Statements
  class RubyCommand < Runbook::Statement
    attr_reader :block

    def initialize(&block)
      @block = block
    end
  end
end
