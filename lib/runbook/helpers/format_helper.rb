module Runbook::Helpers
  module FormatHelper
    def deindent(str)
      lines = str.split("\n")
      indentation = lines[0].size - lines[0].gsub(/^\s+/, "").size
      lines.map! { |line| line[indentation..-1] }
      lines.join("\n")
    end
  end
end
