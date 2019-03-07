module Runbook
  class Toolbox
    attr_reader :prompt

    def initialize
      @prompt = TTY::Prompt.new
    end

    def ask(msg, default: nil)
      prompt.ask(msg, default: default)
    end

    def expand(msg, choices)
      prompt.expand(msg, choices)
    end

    def yes?(msg)
      begin
        prompt.yes?(msg)
      rescue TTY::Prompt::ConversionError
        err_msg = "Unknown input: Please type 'y' or 'n'."
        warn(err_msg)
        retry
      end
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
