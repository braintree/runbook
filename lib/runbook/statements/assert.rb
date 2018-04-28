module Runbook::Statements
  class Assert < Runbook::Statement
    attr_reader :cmd, :cmd_ssh_config, :interval
    attr_reader :timeout, :exec_on_timeout, :exec_on_timeout_ssh_config

    def initialize(
      cmd,
      cmd_ssh_config: nil,
      interval: 1,
      timeout: 0,
      exec_on_timeout: nil,
      exec_on_timeout_ssh_config: nil
    )
      @cmd = cmd
      @cmd_ssh_config = cmd_ssh_config
      @interval = interval
      @timeout = timeout
      @exec_on_timeout = exec_on_timeout
      @exec_on_timeout_ssh_config = exec_on_timeout_ssh_config
    end
  end
end
