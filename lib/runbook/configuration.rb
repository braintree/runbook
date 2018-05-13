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
    attr_accessor :enable_sudo_prompt
    attr_reader :use_same_sudo_password

    GlobalConfigFile = "/etc/runbook.conf"
    ProjectConfigFile = "Runbookfile"
    UserConfigFile = ".runbook.conf"

    def self.load_config
      _load_global_config
      _load_project_config
      _load_user_config
      Runbook.configure
    end

    def self._load_global_config
      load(GlobalConfigFile) if File.exist?(GlobalConfigFile)
    end

    def self._load_project_config
      dir = Dir.pwd
      loop do
        config_path = File.join(dir, ProjectConfigFile)
        if File.exist?(config_path)
          load(config_path)
          return
        end
        break if File.identical?(dir, "/")
        dir = File.join(dir, "..")
      end
    end

    def self._load_user_config
      user_config_file = File.join(ENV["HOME"], UserConfigFile)
      load(user_config_file) if File.exist?(user_config_file)
    end

    def initialize
      self.ssh_kit = SSHKit.config
      ssh_kit.output = Airbrussh::Formatter.new(
        $stdout,
        banner: nil,
        command_output: true,
      )
      self.enable_sudo_prompt = true
      self.use_same_sudo_password = true
    end

    def use_same_sudo_password=(use_same_pwd)
      @use_same_sudo_password = use_same_pwd
      SSHKit::Sudo::InteractionHandler.class_eval do
        if use_same_pwd
          use_same_password!
        else
          def password_cache_key(host)
            "#{host.user}@#{host.hostname}"
          end
        end
      end
    end
  end

  Configuration.load_config
end
