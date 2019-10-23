module Runbook::Extensions
  module Sections
    module DSL
      def section(title, *tags, labels: {}, &block)
        Runbook::Entities::Section.new(
          title,
          tags: tags,
          labels: labels,
        ).tap do |section|
          parent.add(section)
          section.dsl.instance_eval(&block)
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Sections::DSL)
  Runbook::Entities::Section::DSL.prepend(Sections::DSL)
end
