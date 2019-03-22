module Runbook
  module Run
    def self.included(base)
      base.extend(ClassMethods)
      _register_kill_all_panes_hook(base)
      _register_additional_step_whitespace_hook(base)
      ::Runbook::Util::Repo.register_save_repo_hook(base)
      ::Runbook::Util::Repo.register_delete_stored_repo_hook(base)
      ::Runbook::Util::StoredPose.register_save_pose_hook(base)
      ::Runbook::Util::StoredPose.register_delete_stored_pose_hook(base)
    end

    module ClassMethods
      include Runbook::Hooks
      include Runbook::Helpers::FormatHelper
      include Runbook::Helpers::TmuxHelper

      def execute(object, metadata)
        return if should_skip?(metadata)

        method = _method_name(object)
        if respond_to?(method)
          send(method, object, metadata)
        else
          msg = "ERROR! No execution rule for #{object.class} (#{_method_name(object)}) in #{to_s}"
          metadata[:toolbox].error(msg)
          return
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
        title = " #{object.title}".rstrip
        toolbox.output("Step #{metadata[:position]}:#{title}\n\n")
        return if metadata[:auto] || metadata[:noop] ||
          !metadata[:paranoid] || object.title.nil?
        continue_result = toolbox.expand("Continue?", _step_choices)
        _handle_continue_result(continue_result, object, metadata)
      end

      def runbook__statements__ask(object, metadata)
        target = object.parent.dsl
        existing_val = target.instance_variable_get(:"@#{object.into}")
        default = existing_val || object.default

        if metadata[:auto]
          if default
            target.singleton_class.class_eval { attr_accessor object.into }
            target.send("#{object.into}=".to_sym, default)
            return
          end

          error_msg = "ERROR! Can't execute ask statement without default in automatic mode!"
          metadata[:toolbox].error(error_msg)
          raise Runbook::Runner::ExecutionError, error_msg
        end

        if metadata[:noop]
          default_msg = default ? " (default: #{default})" : ""
          metadata[:toolbox].output("[NOOP] Ask: #{object.prompt} (store in: #{object.into})#{default_msg}")
          return
        end

        result = metadata[:toolbox].ask(object.prompt, default: default)

        target = object.parent.dsl
        target.singleton_class.class_eval { attr_accessor object.into }
        target.send("#{object.into}=".to_sym, result)
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

      def runbook__statements__layout(object, metadata)
        if metadata[:noop]
          metadata[:toolbox].output(
            "[NOOP] Layout: #{object.structure.inspect}"
          )
          unless ENV["TMUX"]
            msg = "Warning: layout statement called outside a tmux pane."
            metadata[:toolbox].warn(msg)
          end
          return
        end

        unless ENV["TMUX"]
          error_msg = "Error: layout statement called outside a tmux pane. Exiting..."
          metadata[:toolbox].error(error_msg)
          metadata[:toolbox].exit(1)
        end

        structure = object.structure
        title = object.parent.title
        layout_panes = setup_layout(structure, runbook_title: title)
        metadata[:layout_panes].merge!(layout_panes)
      end

      def runbook__statements__note(object, metadata)
        metadata[:toolbox].output("Note: #{object.msg}")
      end

      def runbook__statements__notice(object, metadata)
        metadata[:toolbox].warn("Notice: #{object.msg}")
      end

      def runbook__statements__tmux_command(object, metadata)
        if metadata[:noop]
          metadata[:toolbox].output("[NOOP] Run: `#{object.cmd}` in pane #{object.pane}")
          return
        end

        send_keys(object.cmd, metadata[:layout_panes][object.pane])
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

        next_index = metadata[:index] + 1
        parent_items = object.parent.items
        remaining_items = parent_items.slice!(next_index..-1)
        object.parent.dsl.instance_exec(object, metadata, &object.block)
        parent_items.push(*remaining_items)
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

      def should_skip?(metadata)
        if metadata[:reversed] && metadata[:position].empty?
          current_pose = "0"
        else
          current_pose = metadata[:position]
        end
        return false if current_pose.empty?
        position = Gem::Version.new(current_pose)
        start_at = Gem::Version.new(metadata[:start_at])
        return position < start_at
      end

      def start_at_is_substep?(object, metadata)
        return false unless object.is_a?(Entity)
        return true if metadata[:position].empty?
        metadata[:start_at].start_with?(metadata[:position])
      end

      def past_position?(current_position, position)
        current_pose = Gem::Version.new(current_position)
        pose = Gem::Version.new(position)
        return pose <= current_pose
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
          metadata[:start_at] = start_at
        when :jump
          result = toolbox.ask("What position would you like to jump to?")
          if past_position?(metadata[:position], result)
            metadata[:reverse] = true
            metadata[:reversed] = true
          end
          metadata[:start_at] = result
        when :no_paranoid
          metadata[:paranoid] = false
        when :exit
          toolbox.exit(0)
        end
      end
    end

    def self._register_kill_all_panes_hook(base)
      base.register_hook(
        :kill_all_panes_after_book,
        :after,
        Runbook::Entities::Book,
      ) do |object, metadata|
        next if metadata[:noop] || metadata[:layout_panes].none?
        if metadata[:auto]
          metadata[:toolbox].output("Killing all opened tmux panes...")
          kill_all_panes(metadata[:layout_panes])
        else
          prompt = "Kill all opened panes?"
          result = metadata[:toolbox].yes?(prompt)
          if result
            kill_all_panes(metadata[:layout_panes])
          end
        end
      end
    end

    def self._register_additional_step_whitespace_hook(base)
      base.register_hook(
        :add_additional_step_whitespace_hook,
        :after,
        Runbook::Statement,
      ) do |object, metadata|
        if object.parent.is_a?(Runbook::Entities::Step)
          if object.parent.items.last == object
            metadata[:toolbox].output("\n")
          end
        end
      end
    end
  end
end
