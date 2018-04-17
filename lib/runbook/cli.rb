require "runbook"
require "thor"

module Runbook
  class CLI < Thor
    desc "view RUNBOOK", "Generates a formatted version of the runbook"
    def view(runbook)
      runbook = eval(File.read(runbook))
      puts Runbook::Viewer.new(runbook).generate(:markdown)
    end
  end
end
