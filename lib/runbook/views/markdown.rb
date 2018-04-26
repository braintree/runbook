module Runbook::Views
  module Markdown
    include Runbook::View

    def self.runbook__entities__book(object, output, metadata)
      output << "# #{object.title}\n\n"
    end

    def self.runbook__entities__section(object, output, metadata)
      heading = "#"*metadata[:depth]
      output << "#{heading} #{metadata[:index]+1}. #{object.title}\n\n"
    end

    def self.runbook__entities__step(object, output, metadata)
      output << "#{metadata[:index]+1}. [] #{object.title}\n\n"
    end

    def self.runbook__statements__ask(object, output, metadata)
      output << "   #{object.prompt}\n\n"
    end

    def self.runbook__statements__assert(object, output, metadata)
      output << "   run: `#{object.cmd}` every #{object.interval} seconds until it returns 0\n\n"
      if object.timeout > 0
        exec_on_timeout_msg = object.exec_on_timeout ? " and run `#{object.exec_on_timeout}`" : ""
        output << "   after #{object.timeout} seconds, time out#{exec_on_timeout_msg}\n\n"
      end
    end

    def self.runbook__statements__command(object, output, metadata)
      output << "   run: `#{object.cmd}`\n\n"
    end

    def self.runbook__statements__condition(object, output, metadata)
      begin
        output << "   if (#{object.predicate.source})\n\n"
        output << "   then (#{object.if_stmt.source})\n\n"
        output << "   else (#{object.else_stmt.source})\n\n" if object.else_stmt
      rescue MethodSource::SourceNotFoundError => e
        output << "   Unable to retrieve source code\n\n"
      end
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
        output << "   #{object.block.source}"
      rescue MethodSource::SourceNotFoundError => e
        output << "   Unable to retrieve source code\n"
      end
      output << "   ```\n\n"
    end

    def self.runbook__statements__wait(object, output, metadata)
      output << "   wait: #{object.time} seconds\n\n"
    end
  end
end
