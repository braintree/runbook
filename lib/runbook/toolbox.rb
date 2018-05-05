module Runbook
  class Toolbox
    attr_reader :prompt

    def initialize
      @prompt = TTY::Prompt.new
    end

    def ask(msg)
      prompt.ask(msg)
    end

    def yes?(msg)
      prompt.yes?(msg)
    end

    def output(msg)
      prompt.say(msg)
    end

    def warn(msg)
      prompt.warn(msg)
    end

    def error(msg)
      prompt.error(msg)
    end

    def exit(return_value)
      super(return_value)
    end
  end
end
