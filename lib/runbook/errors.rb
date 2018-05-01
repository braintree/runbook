module Runbook
  StandardError = Class.new(::StandardError)

  class Runner
    ExecutionError = Class.new(Runbook::StandardError)
  end
end
