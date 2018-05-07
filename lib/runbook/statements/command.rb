module Runbook::Statements
  class Command < Runbook::Statement
    attr_reader :cmd, :ssh_config, :raw

    def initialize(cmd, ssh_config: nil, raw: false)
      @cmd = cmd
      @ssh_config = ssh_config
      @raw = raw
    end
  end
end
