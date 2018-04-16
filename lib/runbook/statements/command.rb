module Runbook::Statements
  class Command < Runbook::Statement
    attr_reader :cmd

    def initialize(cmd)
      @cmd = cmd
    end
  end
end
