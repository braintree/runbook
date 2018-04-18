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
  end
end
