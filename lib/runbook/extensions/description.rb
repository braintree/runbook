module Runbook::Extensions
  module Description
    def description(msg)
      Runbook::Statements::Description.new(msg).tap do |desc|
        items << desc
      end
    end
  end

  Runbook::Entities::Book.prepend(Description)
  Runbook::Entities::Section.prepend(Description)
end
