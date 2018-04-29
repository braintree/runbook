module Runbook::Statements
  class Assert < Runbook::Statement
    attr_reader :cmd, :cmd_ssh_config, :interval
    attr_reader :timeout, :timeout_cmd, :timeout_cmd_ssh_config

    def initialize(
      cmd,
      cmd_ssh_config: nil,
      interval: 1,
      timeout: 0,
      timeout_cmd: nil,
      timeout_cmd_ssh_config: nil
    )
      @cmd = cmd
      @cmd_ssh_config = cmd_ssh_config
      @interval = interval
      @timeout = timeout
      @timeout_cmd = timeout_cmd
      @timeout_cmd_ssh_config = timeout_cmd_ssh_config
    end
  end
end
