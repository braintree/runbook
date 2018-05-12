module Runbook::Views
  module Markdown
    include Runbook::View
    extend Runbook::Helpers::FormatHelper

    def self.runbook__entities__book(object, output, metadata)
      output << "# #{object.title}\n\n"
    end

    def self.runbook__entities__section(object, output, metadata)
      heading = "#"*metadata[:depth]
      output << "#{heading} #{metadata[:index]+1}. #{object.title}\n\n"
    end

    def self.runbook__entities__step(object, output, metadata)
      output << "#{metadata[:index]+1}. [] #{object.title}\n\n"

      ssh_config_output = _render_ssh_config_output(object.ssh_config)
      output << "#{ssh_config_output}\n" unless ssh_config_output.empty?
    end

    def self.runbook__statements__ask(object, output, metadata)
      output << "   #{object.prompt}\n\n"
    end

    def self.runbook__statements__assert(object, output, metadata)
      output << "   run: `#{object.cmd}` every #{object.interval} seconds until it returns 0\n\n"
      if object.timeout > 0
        timeout_cmd_msg = object.timeout_cmd ? " run `#{object.timeout_cmd}` and" : ""
        output << "   after #{object.timeout} seconds, #{timeout_cmd_msg} exit\n\n"
      end
    end

    def self.runbook__statements__capture(object, output, metadata)
      output << "   capture: `#{object.cmd}` into #{object.into}\n\n"
    end

    def self.runbook__statements__command(object, output, metadata)
      output << "   run: `#{object.cmd}`\n\n"
    end

    def self.runbook__statements__confirm(object, output, metadata)
      output << "   confirm: #{object.prompt}\n\n"
    end

    def self.runbook__statements__description(object, output, metadata)
      output << "#{object.msg}\n"
    end

    def self.runbook__statements__monitor(object, output, metadata)
      output << "   run: `#{object.cmd}`\n\n"
      output << "   confirm: #{object.prompt}\n\n"
    end

    def self.runbook__statements__note(object, output, metadata)
      output << "   #{object.msg}\n\n"
    end

    def self.runbook__statements__notice(object, output, metadata)
      output << "   **#{object.msg}**\n\n"
    end

    def self.runbook__statements__ruby_command(object, output, metadata)
      output << "   run:\n"
      output << "   ```ruby\n"
      begin
        output << "   #{deindent(object.block.source)}"
      rescue ::MethodSource::SourceNotFoundError => e
        output << "   Unable to retrieve source code\n"
      end
      output << "   ```\n\n"
    end

    def self.runbook__statements__wait(object, output, metadata)
      output << "   wait: #{object.time} seconds\n\n"
    end

    def self._render_ssh_config_output(ssh_config)
      "".tap do |output|
        if (servers = ssh_config[:servers]).any?
          server_str = servers.join(", ")
          if server_str.size > 80
            server_str = "#{server_str[0..38]}...#{server_str[-38..-1]}"
          end
          output << "   on: #{server_str}\n"
        end

        if (strategy = ssh_config[:parallelization][:strategy])
          limit = ssh_config[:parallelization][:limit]
          wait = ssh_config[:parallelization][:wait]
          in_str = "   in: #{strategy}"
          in_str << ", limit: #{limit}" if strategy == :groups
          in_str << ", wait: #{wait}" if [:sequence, :groups].include?(strategy)
          output << "#{in_str}\n"
        end

        if ssh_config[:user] || ssh_config[:group]
          user = ssh_config[:user]
          group = ssh_config[:group]
          as_str = "   as:"
          as_str << " user: #{user}" if user
          as_str << " group: #{group}" if group
          output << "#{as_str}\n"
        end

        if (path = ssh_config[:path])
          output << "   within: #{path}\n"
        end

        if (env = ssh_config[:env])
          env_str = env.map do |k, v|
            "#{k.to_s.upcase}=#{v}"
          end.join(" ")
          output << "   with: #{env_str}\n"
        end

        if (umask = ssh_config[:umask])
          output << "   umask: #{umask}\n"
        end
      end
    end
  end
end
