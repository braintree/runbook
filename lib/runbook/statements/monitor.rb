module Runbook::Statements
  class Monitor
    attr_reader :cmd, :prompt

    def initialize(cmd: , prompt:)
      @cmd = cmd
      @prompt = prompt
    end
  end
end
