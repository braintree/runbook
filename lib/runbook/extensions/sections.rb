module Runbook::Extensions
  module Sections
    module DSL
      def section(title, &block)
        Runbook::Entities::Section.new(title).tap do |section|
          parent.items << section
          section.dsl.instance_eval(&block)
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Sections::DSL)
  Runbook::Entities::Section::DSL.prepend(Sections::DSL)
end
