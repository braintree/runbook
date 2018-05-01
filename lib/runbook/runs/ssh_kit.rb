module Runbook::Runs
  class SSHKit < Runbook::Run
    include Runbook::Helpers::SSHKitHelper

    def runbook__statements__assert(object, metadata)
      if metadata[:noop]
        interval_msg = "(running every #{object.interval} second(s))"
        _output("[NOOP] Assert: #{object.cmd} returns 0 #{interval_msg}")
        if object.timeout > 0
          timeout_msg = object.timeout_cmd ? " run `#{object.timeout_cmd}` and" : ""
          timeout_msg = "after #{object.timeout} seconds,#{timeout_msg} exit"
          _output(timeout_msg)
        end
        return
      end

      time = Time.now
      cmd_ssh_config = object.cmd_ssh_config || metadata[:parent].ssh_config
      timed_out = false
      test_args = ssh_kit_command(object.cmd)

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
        _error(error_msg)
        if (timeout_cmd = object.timeout_cmd)
          ssh_config = object.timeout_cmd_ssh_config ||
            metadata[:parent].ssh_config
          timeout_cmd_args = ssh_kit_command(timeout_cmd)
          with_ssh_config(ssh_config) do
            execute(*timeout_cmd_args)
          end
        end
        raise Runbook::Runner::ExecutionError, error_msg
      end
    end

    def runbook__statements__command(object, metadata)
      if metadata[:noop]
        _output("[NOOP] Run: `#{object.cmd}`")
        return
      end

      _output("\n") # for formatting

      ssh_config = object.ssh_config || metadata[:parent].ssh_config
      execute_args = ssh_kit_command(object.cmd)

      with_ssh_config(ssh_config) do
        execute(*execute_args)
      end
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
  end
end

