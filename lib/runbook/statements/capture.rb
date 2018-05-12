module Runbook::Statements
  class Capture < Runbook::Statement
    attr_reader :cmd, :into, :ssh_config, :raw, :strip

    def initialize(cmd, into:, ssh_config: nil, raw: false, strip: true)
      @cmd = cmd
      @into = into
      @ssh_config = ssh_config
      @raw = raw
      @strip = strip
    end
  end
end

