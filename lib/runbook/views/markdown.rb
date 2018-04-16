module Runbook::Views
  module Markdown
    def self.render_before(object, output)
      case object
      when Runbook::Entities::Book
        output << "# #{object.title}\n\n"
      when Runbook::Entities::Section
        output << "## 1. #{object.title}\n\n"
      when Runbook::Entities::Step
        output << "1. [] #{object.title}\n"
      when Runbook::Statements::Ask
        output << "   #{object.prompt}\n"
      when Runbook::Statements::Assert
        output << "   run: \`#{object.cmd}\` every #{object.interval} seconds until it returns 0\n"
        if object.timeout > 0
          exec_on_timeout_msg = object.exec_on_timeout ? " and run \`#{object.exec_on_timeout}\`" : ""
          output << "   after #{object.timeout} seconds, time out#{exec_on_timeout_msg}\n"
        end
      when Runbook::Statements::Command
        output << "   run: \`#{object.cmd}\`\n"
      when Runbook::Statements::Condition
        begin
          output << "   if (#{object.predicate.source})\n"
          output << "   then (#{object.if_stmt.source})\n"
          output << "   else (#{object.else_stmt.source})\n" if object.else_stmt
        rescue MethodSource::SourceNotFoundError => e
          output << "   Unable to retrieve source code\n"
        end
      when Runbook::Statements::Confirm
        output << "   confirm: #{object.prompt}\n"
      when Runbook::Statements::Monitor
        output << "   run: \`#{object.cmd}\`\n"
        output << "   confirm: #{object.prompt}\n"
      when Runbook::Statements::Note
        output << "   note: #{object.msg}\n"
      when Runbook::Statements::Notice
        output << "   **notice**: #{object.msg}\n"
      when Runbook::Statements::Wait
        output << "   wait: #{object.time} seconds\n"
      else
        # TODO: How do we handle error output?
        puts "WARNING! No _before_ render rule for #{object.class} for Runbook::Views::Markdown"
      end
    end

    def self.render_after(object, output)
      case object
      when Runbook::Entities::Book
      when Runbook::Entities::Section
        output << "\n"
      when Runbook::Entities::Step
      when Runbook::Statements::Ask
      when Runbook::Statements::Assert
      when Runbook::Statements::Command
      when Runbook::Statements::Condition
      when Runbook::Statements::Confirm
      when Runbook::Statements::Monitor
      when Runbook::Statements::Note
      when Runbook::Statements::Notice
      when Runbook::Statements::Wait
      else
        # TODO: How do we handle error output?
        puts "WARNING! No _after_ render rule for #{object.class} for Runbook::Views::Markdown"
      end
    end
  end
end
