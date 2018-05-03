module Runbook
  class Run
    attr_reader :prompt

    def initialize
      @prompt = TTY::Prompt.new
    end

    def execute(object,  metadata)
      position = Gem::Version.new(metadata[:position])
      start_at = Gem::Version.new(metadata[:start_at])
      return unless metadata[:position].empty? || position >= start_at

      send(_method_name(object), object, metadata)

      if metadata[:parent].is_a?(Runbook::Entities::Step)
        if metadata[:parent].items.last == object
          _output("\n")
        end
      end
    rescue NoMethodError
      _error("ERROR! No execution rule for #{object.class} (#{_method_name(object)}) in #{to_s}")
    end

    def runbook__entities__book(object, metadata)
      _output("Executing #{object.title}...\n\n")
    end

    def runbook__entities__section(object, metadata)
      _output("Section #{metadata[:position]}: #{object.title}\n\n")
    end

    def runbook__entities__step(object, metadata)
      _output("Step #{metadata[:position]}: #{object.title}\n\n")
    end

    def runbook__statements__ask(object, metadata)
      if metadata[:auto]
        error_msg = "ERROR! Can't execute ask statement in automatic mode!"
        _error(error_msg)
        raise Runbook::Runner::ExecutionError, error_msg
      end

      if metadata[:noop]
        _output("[NOOP] Ask: #{object.prompt} (store in: #{object.into})")
        return
      end

      result = prompt.ask(object.prompt)
      metadata[:parent].define_singleton_method(object.into.to_sym) do
        result
      end
    end

    def runbook__statements__confirm(object, metadata)
      if metadata[:auto]
        _output("Skipping confirmation (auto): #{object.prompt}")
      else
        if metadata[:noop]
          _output("[NOOP] Prompt: #{object.prompt}")
          return
        end

        result = prompt.yes?(object.prompt)
        _exit(1) unless result
      end
    end

    def runbook__statements__description(object, metadata)
      _output("Description:")
      _output("#{object.msg}\n")
    end

    def runbook__statements__monitor(object, metadata)
      _output("Run the following in a separate pane:")
      _output("`#{object.cmd}`")
      if metadata[:auto]
        _output("Skipping confirmation (auto): #{object.prompt}")
      else
        if metadata[:noop]
          _output("[NOOP] Prompt: #{object.prompt}")
          return
        end

        result = prompt.yes?(object.prompt)
        _exit(1) unless result
      end
    end

    def runbook__statements__note(object, metadata)
      _output("Note: #{object.msg}")
    end

    def runbook__statements__notice(object, metadata)
      _warn("Notice: #{object.msg}")
    end

    def runbook__statements__ruby_command(object, metadata)
      if metadata[:noop]
        _output("\n[NOOP] Run the following Ruby block:\n")
        begin
          source = object.block.source
          lines = source.split("\n")
          indentation = lines[0].size - lines[0].gsub(/^\s+/, "").size
          lines.map! { |line| line[indentation..-1] }
          _output("```ruby\n#{lines.join("\n")}\n```\n")
        rescue ::MethodSource::SourceNotFoundError => e
          _output("Unable to retrieve source code")
        end
        return
      end

      self.instance_exec(object, metadata, &object.block)
    end

    def runbook__statements__wait(object, metadata)
      if metadata[:noop]
        _output("[NOOP] Sleep #{object.time} seconds")
        return
      end

      time = object.time
      message = "Sleeping #{time} seconds [:bar] :current/:total"
      pastel = Pastel.new
      yellow = pastel.on_yellow(" ")
      green = pastel.on_green(" ")
      progress_bar = TTY::ProgressBar.new(
        message,
        total: time,
        width: 60,
        head: ">",
        incomplete: yellow,
        complete: green,
      )
      progress_bar.start
      time.times do
        sleep(1)
        progress_bar.advance(1)
      end
    end

    def _method_name(object)
      object.class.to_s.underscore.gsub("/", "__")
    end

    def _output(msg)
      prompt.say(msg)
    end

    def _warn(msg)
      prompt.warn(msg)
    end

    def _error(msg)
      prompt.error(msg)
    end

    def _exit(return_value)
      exit(return_value)
    end
  end
end
