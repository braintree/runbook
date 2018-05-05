module Runbook
  module Run
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def execute(object,  metadata)
        position = Gem::Version.new(metadata[:position])
        start_at = Gem::Version.new(metadata[:start_at])
        return unless metadata[:position].empty? || position >= start_at

        method = _method_name(object)
        if respond_to?(method)
          send(method, object, metadata)
        else
          msg = "ERROR! No execution rule for #{object.class} (#{_method_name(object)}) in #{to_s}"
          metadata[:toolbox].error(msg)
          return
        end

        if metadata[:parent].is_a?(Runbook::Entities::Step)
          if metadata[:parent].items.last == object
            metadata[:toolbox].output("\n")
          end
        end
      end

      def runbook__entities__book(object, metadata)
        metadata[:toolbox].output("Executing #{object.title}...\n\n")
      end

      def runbook__entities__section(object, metadata)
        metadata[:toolbox].output("Section #{metadata[:position]}: #{object.title}\n\n")
      end

      def runbook__entities__step(object, metadata)
        metadata[:toolbox].output("Step #{metadata[:position]}: #{object.title}\n\n")
      end

      def runbook__statements__ask(object, metadata)
        if metadata[:auto]
          error_msg = "ERROR! Can't execute ask statement in automatic mode!"
          metadata[:toolbox].error(error_msg)
          raise Runbook::Runner::ExecutionError, error_msg
        end

        if metadata[:noop]
          metadata[:toolbox].output("[NOOP] Ask: #{object.prompt} (store in: #{object.into})")
          return
        end

        result = metadata[:toolbox].ask(object.prompt)
        metadata[:parent].define_singleton_method(object.into.to_sym) do
          result
        end
      end

      def runbook__statements__confirm(object, metadata)
        if metadata[:auto]
          metadata[:toolbox].output("Skipping confirmation (auto): #{object.prompt}")
        else
          if metadata[:noop]
            metadata[:toolbox].output("[NOOP] Prompt: #{object.prompt}")
            return
          end

          result = metadata[:toolbox].yes?(object.prompt)
          metadata[:toolbox].exit(1) unless result
        end
      end

      def runbook__statements__description(object, metadata)
        metadata[:toolbox].output("Description:")
        metadata[:toolbox].output("#{object.msg}\n")
      end

      def runbook__statements__monitor(object, metadata)
        metadata[:toolbox].output("Run the following in a separate pane:")
        metadata[:toolbox].output("`#{object.cmd}`")
        if metadata[:auto]
          metadata[:toolbox].output("Skipping confirmation (auto): #{object.prompt}")
        else
          if metadata[:noop]
            metadata[:toolbox].output("[NOOP] Prompt: #{object.prompt}")
            return
          end

          result = metadata[:toolbox].yes?(object.prompt)
          metadata[:toolbox].exit(1) unless result
        end
      end

      def runbook__statements__note(object, metadata)
        metadata[:toolbox].output("Note: #{object.msg}")
      end

      def runbook__statements__notice(object, metadata)
        metadata[:toolbox].warn("Notice: #{object.msg}")
      end

      def runbook__statements__ruby_command(object, metadata)
        if metadata[:noop]
          metadata[:toolbox].output("\n[NOOP] Run the following Ruby block:\n")
          begin
            source = deindent(object.block.source)
            metadata[:toolbox].output("```ruby\n#{source}\n```\n")
          rescue ::MethodSource::SourceNotFoundError => e
            metadata[:toolbox].output("Unable to retrieve source code")
          end
          return
        end

        self.instance_exec(object, metadata, &object.block)
      end

      def runbook__statements__wait(object, metadata)
        if metadata[:noop]
          metadata[:toolbox].output("[NOOP] Sleep #{object.time} seconds")
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
    end
  end
end
