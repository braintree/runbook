module Runbook
  class Viewer
    attr_reader :book

    def initialize(book)
      @book = book
    end

    def generate(view)
      view = "Runbook::Views::#{view.to_s.camelize}".constantize
      StringIO.new.tap do |output|
        book.render(view, output)
      end.string
    end
  end
end
