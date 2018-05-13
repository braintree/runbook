require "thor"
require "runbook"

module Runbook
  class CLI < Thor
    class_option :config, aliases: :c, type: :string

    desc "view RUNBOOK", "Generates a formatted version of the runbook"
    long_desc <<-LONGDESC
      Executes the runbook.

      With --view (-v), Generates the view with the specified view type
    LONGDESC
    option :view, aliases: :v, type: :string, default: :markdown
    def view(runbook)
      _load_config(options[:config], :view) if options[:config]
      runbook = _retrieve_runbook(runbook, :view)
      puts Runbook::Viewer.new(runbook).generate(options[:view])
    end

    desc "exec RUNBOOK", "Executes the runbook"
    long_desc <<-LONGDESC
      Executes the runbook.

      With --noop (-n), Runs the runbook in no-op mode, preventing commands from executing.

      With --auto (-a), Runs the runbook in auto mode. This will prevent the execution from asking for any user input (such as confirmations). Not all runbooks are compatible with auto mode (if they use the ask statement for example).

      With --run (-r), Runs the runbook with the specified run type

      With --no-paranoid (-P), Runs the runbook without prompting to continue at every step

      With --start-at (-s), Runs the runbook starting at the specified section or step.
    LONGDESC
    option :run, aliases: :r, type: :string, default: :ssh_kit
    option :noop, aliases: :n, type: :boolean
    option :auto, aliases: :a, type: :boolean
    option :"no-paranoid", aliases: :P, type: :boolean
    option :start_at, aliases: :s, type: :string
    def exec(runbook)
      _load_config(options[:config], :exec) if options[:config]
      runbook = _retrieve_runbook(runbook, :exec)
      Runbook::Runner.new(runbook).run(
        run: options[:run],
        noop: options[:noop],
        auto: options[:auto],
        paranoid: options[:paranoid],
        start_at: options[:start_at],
      )
    end

    private

    def _load_config(config, cmd)
      unless File.exist?(config)
        raise Thor::UnknownArgumentError, "#{cmd}: cannot access #{config}: No such file or directory"
      end
      load(config)
    end

    def _retrieve_runbook(runbook, cmd)
      unless File.exist?(runbook)
        raise Thor::UnknownArgumentError, "#{cmd}: cannot access #{runbook}: No such file or directory"
      end
      load(runbook)
      runbook_key = File.basename(runbook, ".rb").to_sym
      Runbook.books[runbook_key] || eval(File.read(runbook))
    end
  end
end
