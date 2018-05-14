module Runbook::Statements
  class Assert < Runbook::Statement
    attr_reader :cmd, :cmd_ssh_config, :cmd_raw
    attr_reader :interval, :timeout, :timeout_statement

    def initialize(
      cmd,
      cmd_ssh_config: nil,
      cmd_raw: false,
      interval: 1,
      timeout: 0,
      timeout_statement: nil
    )
      @cmd = cmd
      @cmd_ssh_config = cmd_ssh_config
      @cmd_raw = cmd_raw
      @interval = interval
      @timeout = timeout
      @timeout_statement = timeout_statement
    end
  end
end
