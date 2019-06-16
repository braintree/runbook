module Runbook::CLIBase
  def self.included(base)
    base.check_unknown_options!

    base.class_option(
      :config,
      aliases: "-c",
      type: :string,
      group: :base,
      desc: "Path to runbook config file"
    )
  end

  def initialize(args = [], local_options = {}, config = {})
    super(args, local_options, config)

    cmd_name = config[:current_command].name
    _set_cli_config(options[:config], cmd_name) if options[:config]
  end

  protected

  def _set_cli_config(config, cmd)
    unless File.exist?(config)
      raise Thor::InvocationError, "#{cmd}: cannot access #{config}: No such file or directory"
    end
    Runbook::Configuration.cli_config_file = config
    Runbook::Configuration.reconfigure
  end
end
