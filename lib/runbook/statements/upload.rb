module Runbook::Statements
  class Upload < Runbook::Statement
    attr_reader :from, :to, :options, :ssh_config

    def initialize(from, to:, ssh_config: nil, options: {})
      @from = from
      @to = to
      @ssh_config = ssh_config
      @options = options
    end
  end
end
