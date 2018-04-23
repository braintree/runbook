module Runbook::Statements
  class RubyCommand < Runbook::Statement
    attr_reader :cmd

    def initialize(cmd)
      @cmd = cmd
    end
  end
end
