module Runbook
  class Book
    attr_reader :title

    def initialize(title)
      @title = title
    end

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
    prepend Sections
  end
end
