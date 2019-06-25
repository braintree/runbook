require "thor"
require "runbook"
require "runbook/cli_base"
require "runbook/installer"

# Needed to load custom generators
Runbook::Configuration.load_config
require "runbook/generator"

module Runbook
  class CLI < Thor
    include ::Runbook::CLIBase

    map "--version" => :__print_version

    desc "view RUNBOOK", "Prints a formatted version of the runbook"
    long_desc <<-LONGDESC
      Prints the runbook.

      With --view (-v), Prints the view using the specified view type
    LONGDESC
    option :view, aliases: "-v", type: :string, default: :markdown
    def view(runbook)
      runbook = _retrieve_runbook(runbook, :view)
      puts Runbook::Viewer.new(runbook).generate(
        view: options[:view],
      )
    end

    desc "exec RUNBOOK", "Executes the runbook"
    long_desc <<-LONGDESC
      Executes the runbook.

      With --noop (-n),        Runs the runbook in no-op mode, preventing
                               commands from executing.

      With --auto (-a),        Runs the runbook in auto mode. This
                               will prevent the execution from asking
                               for any user input (such as confirmations).
                               Not all runbooks are compatible with auto
                               mode (if they use the ask statement without
                               defaults for example).

      With --run (-r),         Runs the runbook with the specified run type

      With --no-paranoid (-P), Runs the runbook without prompting to
                               continue at every step

      With --start-at (-s),    Runs the runbook starting at the specified
                               section or step.
    LONGDESC
    option :run, aliases: "-r", type: :string, default: :ssh_kit
    option :noop, aliases: "-n", type: :boolean
    option :auto, aliases: "-a", type: :boolean
    option :"no-paranoid", aliases: "-P", type: :boolean
    option :start_at, aliases: "-s", type: :string, default: "0"
    def exec(runbook)
      runbook = _retrieve_runbook(runbook, :exec)
      Runbook::Runner.new(runbook).run(
        run: options[:run],
        noop: options[:noop],
        auto: options[:auto],
        paranoid: options[:"no-paranoid"] == nil,
        start_at: options[:start_at],
      )
    end

    desc "generate GENERATOR", "Generate runbook objects from a template, such as runbooks, projects, or plugins."
    long_desc <<-LONGDESC
      Generates a runbook, runbook node, runbook project, or runbook plugin from a template.
    LONGDESC
    subcommand "generate", Runbook::Generator

    desc "install", "Install Runbook into an existing project"
    long_desc "Set up Runbook directory structure and Runbookfile in an existing project for executing runbooks."
    Runbook::Installer.class_options.values.each do |co|
      method_option co.name, desc: co.description, required: co.required,
        default: co.default, aliases: co.aliases, type: co.type,
        banner: co.banner, hide: co.hide
    end
    def install
      invoke(Runbook::Installer)
    end

    desc "--version", "Print runbook's version"
    def __print_version
      puts "Runbook v#{Runbook::VERSION}"
    end

    private

    def _retrieve_runbook(runbook, cmd)
      unless File.exist?(runbook)
        raise Thor::InvocationError, "#{cmd}: cannot access #{runbook}: No such file or directory"
      end
      load(runbook)
      Runbook.books.last || eval(File.read(runbook))
    end
  end
end
