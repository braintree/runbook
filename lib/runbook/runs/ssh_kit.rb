module Runbook::Runs
  module SSHKit
    include Runbook::Run
    extend Runbook::Helpers::SSHKitHelper

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def runbook__statements__assert(object, metadata)
        cmd_ssh_config = find_ssh_config(object, :cmd_ssh_config)

        if metadata[:noop]
          ssh_config_output = render_ssh_config_output(cmd_ssh_config)
          metadata[:toolbox].output(ssh_config_output) unless ssh_config_output.empty?
          interval_msg = "(running every #{object.interval} second(s))"
          metadata[:toolbox].output("[NOOP] Assert: `#{object.cmd}` returns 0 #{interval_msg}")
          if object.timeout > 0 || object.attempts > 0
            timeout_msg = object.timeout > 0 ? "#{object.timeout} second(s)" : nil
            attempts_msg = object.attempts > 0 ? "#{object.attempts} attempts" : nil
            giveup_msg = "after #{[timeout_msg, attempts_msg].compact.join(" or ")}, give up..."
            metadata[:toolbox].output(giveup_msg)
            if object.timeout_statement
              object.timeout_statement.parent = object.parent
              object.timeout_statement.run(self, metadata.dup)
            end
            metadata[:toolbox].output("and exit")
          end
          return
        end

        gave_up = false
        test_args = ssh_kit_command(object.cmd, raw: object.cmd_raw)
        test_options = ssh_kit_command_options(cmd_ssh_config)

        with_ssh_config(cmd_ssh_config) do
          time = Time.now
          count = object.attempts
          while !(test(*test_args, test_options))
            if ((count -= 1) == 0)
              gave_up = true
              break
            end

            if (object.timeout > 0 && Time.now - time > object.timeout)
              gave_up = true
              break
            end

            sleep(object.interval)
          end
        end

        if gave_up
          error_msg = "Error! Assertion `#{object.cmd}` failed"
          metadata[:toolbox].error(error_msg)
          if object.timeout_statement
            object.timeout_statement.parent = object.parent
            object.timeout_statement.run(self, metadata.dup)
          end
          raise Runbook::Runner::ExecutionError, error_msg
        end
      end

      def runbook__statements__capture(object, metadata)
        _handle_capture(object, metadata) do |ssh_config, capture_args, capture_options|
          if (ssh_config[:servers].size > 1)
            warn_msg = "Warning: `capture` does not support multiple servers. Use `capture_all` instead.\n"
            metadata[:toolbox].warn(warn_msg)
          end

          result = ""
          with_ssh_config(ssh_config) do
            result = capture(*capture_args, capture_options)
          end
          result
        end
      end

      def runbook__statements__capture_all(object, metadata)
        _handle_capture(object, metadata) do |ssh_config, capture_args, capture_options|
          result = {}
          mutex = Mutex.new
          with_ssh_config(ssh_config) do
            hostname = self.host.hostname
            capture_result = capture(*capture_args, capture_options)
            mutex.synchronize { result[hostname] = capture_result }
          end
          result
        end
      end

      def _handle_capture(object, metadata, &block)
        ssh_config = find_ssh_config(object)

        if metadata[:noop]
          ssh_config_output = render_ssh_config_output(ssh_config)
          metadata[:toolbox].output(ssh_config_output) unless ssh_config_output.empty?
          metadata[:toolbox].output("[NOOP] Capture: `#{object.cmd}` into #{object.into}")
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        capture_args = ssh_kit_command(object.cmd, raw: object.raw)
        capture_options = ssh_kit_command_options(ssh_config)
        capture_options[:strip] = object.strip
        capture_options[:verbosity] = Logger::INFO

        capture_msg = "Capturing output of `#{object.cmd}`\n\n"
        metadata[:toolbox].output(capture_msg)

        result = block.call(ssh_config, capture_args, capture_options)

        target = object.parent.dsl
        target.singleton_class.class_eval { attr_accessor object.into }
        target.send("#{object.into}=".to_sym, result)
      end

      def runbook__statements__command(object, metadata)
        ssh_config = find_ssh_config(object)

        if metadata[:noop]
          ssh_config_output = render_ssh_config_output(ssh_config)
          metadata[:toolbox].output(ssh_config_output) unless ssh_config_output.empty?
          metadata[:toolbox].output("[NOOP] Run: `#{object.cmd}`")
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        execute_args = ssh_kit_command(object.cmd, raw: object.raw)
        exec_options = ssh_kit_command_options(ssh_config)

        with_ssh_config(ssh_config) do
          execute(*execute_args, exec_options)
        end
      end

      def runbook__statements__download(object, metadata)
        ssh_config = find_ssh_config(object)

        if metadata[:noop]
          ssh_config_output = render_ssh_config_output(ssh_config)
          metadata[:toolbox].output(ssh_config_output) unless ssh_config_output.empty?
          options = object.options
          to = " to #{object.to}" if object.to
          opts = " with options #{options}" unless options == {}
          noop_msg = "[NOOP] Download: #{object.from}#{to}#{opts}"
          metadata[:toolbox].output(noop_msg)
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        with_ssh_config(ssh_config) do
          download!(object.from, object.to, object.options)
        end
      end

      def runbook__statements__upload(object, metadata)
        ssh_config = find_ssh_config(object)

        if metadata[:noop]
          ssh_config_output = render_ssh_config_output(ssh_config)
          metadata[:toolbox].output(ssh_config_output) unless ssh_config_output.empty?
          options = object.options
          to = " to #{object.to}" if object.to
          opts = " with options #{options}" unless options == {}
          noop_msg = "[NOOP] Upload: #{object.from}#{to}#{opts}"
          metadata[:toolbox].output(noop_msg)
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        with_ssh_config(ssh_config) do
          upload!(object.from, object.to, object.options)
        end
      end
    end

    extend ClassMethods
  end
end
