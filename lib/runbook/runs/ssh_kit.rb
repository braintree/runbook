module Runbook::Runs
  module SSHKit
    include Runbook::Run
    extend Runbook::Helpers::SSHKitHelper

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def runbook__statements__assert(object, metadata)
        if metadata[:noop]
          interval_msg = "(running every #{object.interval} second(s))"
          metadata[:toolbox].output("[NOOP] Assert: `#{object.cmd}` returns 0 #{interval_msg}")
          if object.timeout > 0
            timeout_msg = object.timeout_cmd ? " run `#{object.timeout_cmd}` and" : ""
            timeout_msg = "after #{object.timeout} seconds,#{timeout_msg} exit"
            metadata[:toolbox].output(timeout_msg)
          end
          return
        end

        time = Time.now
        cmd_ssh_config = find_ssh_config(object, :cmd_ssh_config)
        timed_out = false
        test_args = ssh_kit_command(object.cmd, raw: object.cmd_raw)

        with_ssh_config(cmd_ssh_config) do
          while !(test(*test_args))
            if (object.timeout > 0 && Time.now - time > object.timeout)
              timed_out = true
              break
            end
            sleep(interval)
          end
        end

        if timed_out
          error_msg = "Error! Assertion `#{object.cmd}` failed"
          metadata[:toolbox].error(error_msg)
          if (timeout_cmd = object.timeout_cmd)
            ssh_config = find_ssh_config(object, :timeout_cmd_ssh_config)
            timeout_cmd_args = ssh_kit_command(
              timeout_cmd,
              raw: object.timeout_cmd_raw,
            )
            with_ssh_config(ssh_config) do
              execute(*timeout_cmd_args)
            end
          end
          raise Runbook::Runner::ExecutionError, error_msg
        end
      end

      def runbook__statements__capture(object, metadata)
        if metadata[:noop]
          metadata[:toolbox].output("[NOOP] Capture: `#{object.cmd}` into #{object.into}")
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        ssh_config = find_ssh_config(object)
        capture_args = ssh_kit_command(object.cmd, raw: object.raw)

        result = ""
        with_ssh_config(ssh_config) do
          result = capture(*capture_args, strip: object.strip)
        end

        object.parent.define_singleton_method(object.into.to_sym) do
          result
        end
      end

      def runbook__statements__command(object, metadata)
        if metadata[:noop]
          metadata[:toolbox].output("[NOOP] Run: `#{object.cmd}`")
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        ssh_config = find_ssh_config(object)
        execute_args = ssh_kit_command(object.cmd, raw: object.raw)

        with_ssh_config(ssh_config) do
          execute(*execute_args)
        end
      end

      def runbook__statements__download(object, metadata)
        if metadata[:noop]
          options = object.options
          to = " to #{object.to}" if object.to
          opts = " with options #{options}" unless options == {}
          noop_msg = "[NOOP] Download: #{object.from}#{to}#{opts}"
          metadata[:toolbox].output(noop_msg)
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        ssh_config = find_ssh_config(object)

        with_ssh_config(ssh_config) do
          download!(object.from, object.to, object.options)
        end
      end

      def runbook__statements__upload(object, metadata)
        if metadata[:noop]
          options = object.options
          to = " to #{object.to}" if object.to
          opts = " with options #{options}" unless options == {}
          noop_msg = "[NOOP] Upload: #{object.from}#{to}#{opts}"
          metadata[:toolbox].output(noop_msg)
          return
        end

        metadata[:toolbox].output("\n") # for formatting

        ssh_config = find_ssh_config(object)

        with_ssh_config(ssh_config) do
          upload!(object.from, object.to, object.options)
        end
      end
    end

    extend ClassMethods
  end
end
