module Runbook
  module Sections
    def sections
      @sections ||= []
    end

    def section(title, &block)
      Section.new(title).tap do |section|
        sections << section
        section.instance_eval(&block)
      end
    end
  end

  Runbook::Book.prepend(Sections)
end
