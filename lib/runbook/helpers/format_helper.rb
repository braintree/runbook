module Runbook::Helpers
  module FormatHelper
    def deindent(str, padding: 0)
      lines = str.split("\n")
      indentation = lines[0].size - lines[0].gsub(/^\s+/, "").size
      lines.map! { |line| " " * padding + line[indentation..-1] }
      lines.join("\n")
    end
  end
end
