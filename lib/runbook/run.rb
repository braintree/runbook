module Runbook
  module Run
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Runbook::Helpers::FormatHelper

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

        if object.parent.is_a?(Runbook::Entities::Step)
          if object.parent.items.last == object
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
        toolbox = metadata[:toolbox]
        toolbox.output("Step #{metadata[:position]}: #{object.title}\n\n")
        return if metadata[:auto] || metadata[:noop] || !metadata[:paranoid]
        continue_result = toolbox.expand("Continue?", _step_choices)
        _handle_continue_result(continue_result, object, metadata)
      end

      def runbook__statements__ask(object, metadata)
        if metadata[:auto]
          if object.default
            object.parent.define_singleton_method(object.into.to_sym) do
              object.default
            end
            return
          end

          error_msg = "ERROR! Can't execute ask statement in automatic mode!"
          metadata[:toolbox].error(error_msg)
          raise Runbook::Runner::ExecutionError, error_msg
        end

        if metadata[:noop]
          default_msg = object.default ? " (default: #{object.default})" : ""
          metadata[:toolbox].output("[NOOP] Ask: #{object.prompt} (store in: #{object.into})#{default_msg}")
          return
        end

        result = metadata[:toolbox].ask(object.prompt, default: object.default)
        object.parent.define_singleton_method(object.into.to_sym) do
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
          metadata[:toolbox].output("[NOOP] Run the following Ruby block:\n")
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

      def _step_choices
        [
          {key: "c", name: "Continue to execute this step", value: :continue},
          {key: "s", name: "Skip this step", value: :skip},
          {key: "j", name: "Jump to the specified position", value: :jump},
          {key: "P", name: "Disable paranoid mode", value: :no_paranoid},
          {key: "e", name: "Exit the runbook", value: :exit},
        ]
      end

      def _handle_continue_result(result, object, metadata)
        toolbox = metadata[:toolbox]
        case result
        when :continue
          return
        when :skip
          position = metadata[:position]
          current_step = position.split(".")[-1].to_i
          new_step = current_step + 1
          start_at = position.gsub(/\.#{current_step}$/, ".#{new_step}")
          metadata[:start_at].gsub!(/^.*$/, start_at)
        when :jump
          result = toolbox.ask("What position would you like to jump to?")
          metadata[:start_at].gsub!(/^.*$/, result)
        when :no_paranoid
          metadata[:paranoid] = false
        when :exit
          toolbox.exit(0)
        end
      end
    end
  end
end
