module Runbook::Views
  module Markdown
    def self.render(object, output)
      case object
      when Runbook::Entities::Book
        output << "# #{object.title}\n\n"
      when Runbook::Entities::Section
        output << "## 1. #{object.title}\n\n"
      when Runbook::Entities::Step
        output << "1. [] #{object.title}\n\n"
      when Runbook::Statements::Ask
        output << "   #{object.prompt}\n\n"
      when Runbook::Statements::Assert
        output << "   run: `#{object.cmd}` every #{object.interval} seconds until it returns 0\n\n"
        if object.timeout > 0
          exec_on_timeout_msg = object.exec_on_timeout ? " and run `#{object.exec_on_timeout}`" : ""
          output << "   after #{object.timeout} seconds, time out#{exec_on_timeout_msg}\n\n"
        end
      when Runbook::Statements::Command
        output << "   run: `#{object.cmd}`\n\n"
      when Runbook::Statements::Condition
        begin
          output << "   if (#{object.predicate.source})\n\n"
          output << "   then (#{object.if_stmt.source})\n\n"
          output << "   else (#{object.else_stmt.source})\n\n" if object.else_stmt
        rescue MethodSource::SourceNotFoundError => e
          output << "   Unable to retrieve source code\n\n"
        end
      when Runbook::Statements::Confirm
        output << "   confirm: #{object.prompt}\n\n"
      when Runbook::Statements::Monitor
        output << "   run: `#{object.cmd}`\n\n"
        output << "   confirm: #{object.prompt}\n\n"
      when Runbook::Statements::Note
        output << "   #{object.msg}\n\n"
      when Runbook::Statements::Notice
        output << "   **#{object.msg}**\n\n"
      when Runbook::Statements::Wait
        output << "   wait: #{object.time} seconds\n\n"
      else
        # TODO: How do we handle error output?
        puts "WARNING! No _before_ render rule for #{object.class} for Runbook::Views::Markdown"
      end
    end
  end
end
