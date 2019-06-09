module Runbook::Helpers
  module FormatHelper
    def deindent(str, padding: 0)
      lines = str.split("\n")
      indentations = lines.map { |l| l.size - l.gsub(/^\s+/, "").size }
      min_indentation = indentations.min
      lines.map! { |line| " " * padding + line[min_indentation..-1] }
      lines.join("\n")
    end
  end
end
