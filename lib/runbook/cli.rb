require "thor"
require "runbook"

module Runbook
  class CLI < Thor
    desc "view RUNBOOK", "Generates a formatted version of the runbook"
    def view(runbook)
      unless File.exist?(runbook)
        raise Thor::UnknownArgumentError, "view: cannot access #{runbook}: No such file or directory"
      end
      runbook = eval(File.read(runbook))
      puts Runbook::Viewer.new(runbook).generate(:markdown)
    end

    desc "exec RUNBOOK", "Executes the runbook"
    long_desc <<-LONGDESC
      Executes the runbook.

      With --noop (-n), Runs the runbook in no-op mode, preventing commands from executing.

      With --auto (-a), Runs the runbook in auto mode. This will prevent the execution from asking for any user input (such as confirmations). Not all runbooks are compatible with auto mode (if they use the ask statement for example).

      With --start-at (-s), Runs the runbooks starting at the specified section or step.
    LONGDESC
    option :noop, aliases: :n, type: :boolean
    option :auto, aliases: :a, type: :boolean
    option :start_at, aliases: :s, type: :string
    def exec(runbook)
      unless File.exist?(runbook)
        raise Thor::UnknownArgumentError, "exec: cannot access #{runbook}: No such file or directory"
      end
      runbook = eval(File.read(runbook))
      Runbook::Runner.new(runbook).run(
        run: :ssh_kit,
        noop: options[:noop],
        auto: options[:auto],
        start_at: options[:start_at],
      )
    end
  end
end
