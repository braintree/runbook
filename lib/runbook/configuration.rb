module Runbook
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.reset_configuration
    self.configuration = Configuration.new
  end

  class Configuration
    attr_accessor :ssh_kit

    def initialize
      self.ssh_kit = SSHKit.config
      ssh_kit.output = Airbrussh::Formatter.new(
        $stdout,
        banner: nil,
        command_output: true,
      )
    end
  end

  configure
end