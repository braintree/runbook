module Runbook
  class << self
    attr_accessor :configuration

    def config
      @configuration
    end
  end

  def self.configure
    Configuration.load_config
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.reset_configuration
    self.configuration = Configuration.new
    Configuration.loaded = false
  end

  class Configuration
    attr_accessor :_airbrussh_context
    attr_accessor :ssh_kit
    attr_accessor :enable_sudo_prompt
    attr_reader :use_same_sudo_password

    GlobalConfigFile = "/etc/runbook.conf"
    ProjectConfigFile = "Runbookfile"
    UserConfigFile = ".runbook.conf"

    def self.cli_config_file
      @cli_config_file
    end

    def self.cli_config_file=(cli_config_file)
      @cli_config_file = cli_config_file
    end

    def self.loaded
      @loaded
    end

    def self.loaded=(loaded)
      @loaded = loaded
    end

    def self.load_config
      return if @loaded
      @loaded = true
      _load_global_config
      _load_project_config
      _load_user_config
      _load_cli_config
      # Set defaults
      Runbook.configure
    end

    def self.reconfigure
      @loaded = false
      load_config
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

    def self._load_cli_config
      if cli_config_file && File.exist?(cli_config_file)
        load(cli_config_file)
      end
    end

    def initialize
      self.ssh_kit = SSHKit.config
      formatter = Airbrussh::Formatter.new(
        $stdout,
        banner: nil,
        command_output: true,
        context: AirbrusshContext,
      )
      ssh_kit.output = formatter
      self._airbrussh_context = formatter.formatters.find do |fmt|
        fmt.is_a?(Airbrussh::ConsoleFormatter)
      end.context
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
end
