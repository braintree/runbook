module Runbook::Statements
  class Command
    attr_reader :cmd

    def initialize(cmd)
      @cmd = cmd
    end
  end
end
