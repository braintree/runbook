module Runbook::Statements
  class Assert < Runbook::Statement
    attr_reader :cmd, :cmd_ssh_config, :cmd_raw
    attr_reader :interval, :timeout
    attr_reader :timeout_cmd, :timeout_cmd_ssh_config, :timeout_cmd_raw

    def initialize(
      cmd,
      cmd_ssh_config: nil,
      cmd_raw: false,
      interval: 1,
      timeout: 0,
      timeout_cmd: nil,
      timeout_cmd_ssh_config: nil,
      timeout_cmd_raw: false
    )
      @cmd = cmd
      @cmd_ssh_config = cmd_ssh_config
      @cmd_raw = cmd_raw
      @interval = interval
      @timeout = timeout
      @timeout_cmd = timeout_cmd
      @timeout_cmd_ssh_config = timeout_cmd_ssh_config
      @timeout_cmd_raw = timeout_cmd_raw
    end
  end
end
