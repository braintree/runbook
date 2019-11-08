module Runbook::Views
  module Markdown
    include Runbook::View
    extend Runbook::Helpers::FormatHelper
    extend Runbook::Helpers::SSHKitHelper

    def self.runbook__entities__book(object, output, metadata)
      output << "# #{object.title}\n\n"
    end

    def self.runbook__entities__section(object, output, metadata)
      heading = "#"*metadata[:depth]
      output << "#{heading} #{metadata[:index]+1}. #{object.title}\n\n"
    end

    def self.runbook__entities__step(object, output, metadata)
      output << "#{metadata[:index]+1}. [] #{object.title}\n\n"

      ssh_config = find_ssh_config(object)
      ssh_config_output = render_ssh_config_output(ssh_config)
      output << "#{ssh_config_output}\n" unless ssh_config_output.empty?
    end

    def self.runbook__statements__ask(object, output, metadata)
      default_msg = object.default ?  " (default: #{object.default})" : ""
      output << "   #{object.prompt} into `#{object.into}#{default_msg}`\n\n"
    end

    def self.runbook__statements__assert(object, output, metadata)
      output << "   run: `#{object.cmd}` every #{object.interval} seconds until it returns 0\n\n"
      if object.timeout > 0 || object.attempts > 0
        timeout_msg = object.timeout > 0 ? "#{object.timeout} second(s)" : nil
        attempts_msg = object.attempts > 0 ? "#{object.attempts} attempts" : nil
        abort_msg = "after #{[timeout_msg, attempts_msg].compact.join(" or ")}, abort..."
        output << "   #{abort_msg}\n\n"
        if object.abort_statement
          object.abort_statement.render(self, output, metadata.dup)
        end
        output << "   and exit\n\n"
      end
    end

    def self.runbook__statements__capture(object, output, metadata)
      output << "   capture: `#{object.cmd}` into `#{object.into}`\n\n"
    end

    def self.runbook__statements__capture_all(object, output, metadata)
      output << "   capture_all: `#{object.cmd}` into `#{object.into}`\n\n"
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

    def self.runbook__statements__download(object, output, metadata)
      options = object.options
      to = " to #{object.to}" if object.to
      opts = " with options #{options}" unless options == {}
      output << "   download: #{object.from}#{to}#{opts}\n\n"
    end

    def self.runbook__statements__layout(object, output, metadata)
      output << "layout:\n"
      output << "#{object.structure.inspect}\n\n"
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
        output << "#{deindent(object.block.source, padding: 3)}\n"
      rescue ::MethodSource::SourceNotFoundError => e
        output << "   Unable to retrieve source code\n"
      end
      output << "   ```\n\n"
    end

    def self.runbook__statements__tmux_command(object, output, metadata)
      output << "   run: `#{object.cmd}` in pane #{object.pane}\n\n"
    end

    def self.runbook__statements__upload(object, output, metadata)
      options = object.options
      to = " to #{object.to}" if object.to
      opts = " with options #{options}" unless options == {}
      output << "   upload: #{object.from}#{to}#{opts}\n\n"
    end

    def self.runbook__statements__wait(object, output, metadata)
      output << "   wait: #{object.time} seconds\n\n"
    end
  end
end
