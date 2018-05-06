require "thor"
require "runbook"

module Runbook
  class CLI < Thor
    desc "view RUNBOOK", "Generates a formatted version of the runbook"
    def view(runbook)
      unless File.exist?(runbook)
        raise Thor::UnknownArgumentError, "view: cannot access #{runbook}: No such file or directory"
      end
      runbook = _retrieve_runbook(runbook)
      puts Runbook::Viewer.new(runbook).generate(:markdown)
    end

    desc "exec RUNBOOK", "Executes the runbook"
    long_desc <<-LONGDESC
      Executes the runbook.

      With --noop (-n), Runs the runbook in no-op mode, preventing commands from executing.

      With --auto (-a), Runs the runbook in auto mode. This will prevent the execution from asking for any user input (such as confirmations). Not all runbooks are compatible with auto mode (if they use the ask statement for example).

      With --run (-r), Runs the runbook with the specified run type

      With --start-at (-s), Runs the runbook starting at the specified section or step.
    LONGDESC
    option :run, aliases: :r, type: :string, default: :ssh_kit
    option :noop, aliases: :n, type: :boolean
    option :auto, aliases: :a, type: :boolean
    option :start_at, aliases: :s, type: :string
    def exec(runbook)
      unless File.exist?(runbook)
        raise Thor::UnknownArgumentError, "exec: cannot access #{runbook}: No such file or directory"
      end
      runbook = _retrieve_runbook(runbook)
      Runbook::Runner.new(runbook).run(
        run: options[:run],
        noop: options[:noop],
        auto: options[:auto],
        start_at: options[:start_at],
      )
    end

    private

    def _retrieve_runbook(runbook)
      load(runbook)
      runbook_key = File.basename(runbook, ".rb").to_sym
      Runbook.books[runbook_key] || eval(File.read(runbook))
    end
  end
end
