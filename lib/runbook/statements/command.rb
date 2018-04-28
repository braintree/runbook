module Runbook::Statements
  class Command < Runbook::Statement
    attr_reader :cmd, :ssh_config

    def initialize(cmd, ssh_config: nil)
      @cmd = cmd
      @ssh_config = ssh_config
    end
  end
end
