module Runbook
  class Viewer
    attr_reader :book

    def initialize(book)
      @book = book
    end

    def generate(view: :markdown)
      view = "Runbook::Views::#{view.to_s.camelize}".constantize
      metadata = Util::StickyHash.new.
      merge(Runbook::Entities::Book.initial_render_metadata).
      merge(additional_metadata)

      StringIO.new.tap do |output|
        book.render(view, output, metadata)
      end.string
    end

    def additional_metadata
      {}
    end
  end
end
