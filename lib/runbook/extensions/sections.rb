module Runbook::Extensions
  module Sections
    def section(title, &block)
      Runbook::Entities::Section.new(title).tap do |section|
        items << section
        section.instance_eval(&block)
      end
    end
  end

  Runbook::Entities::Book.prepend(Sections)
end
