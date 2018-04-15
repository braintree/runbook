module Runbook::Statements
  class Assert
    attr_reader :cmd, :interval, :timeout, :exec_on_timeout

    def initialize(cmd, interval: 1, timeout: 0, exec_on_timeout: nil)
      @cmd = cmd
      @interval = interval
      @timeout = timeout
      @exec_on_timeout = exec_on_timeout
    end
  end
end
