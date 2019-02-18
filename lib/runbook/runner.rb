module Runbook
  class Runner
    attr_reader :book

    def initialize(book)
      @book = book
    end

    def run(
      run: :ssh_kit,
      noop: false,
      auto: false,
      paranoid: true,
      start_at: "0"
    )
      run = "Runbook::Runs::#{run.to_s.camelize}".constantize
      toolbox = Runbook::Toolbox.new
      metadata = Util::StickyHash.new.merge({
        noop: noop,
        auto: auto,
        paranoid: Util::Glue.new(paranoid),
        start_at: Util::Glue.new(start_at || "0"),
        toolbox: toolbox,
        book_title: book.title,
      }).
      merge(Runbook::Entities::Book.initial_run_metadata).
      merge(additional_metadata)

      if metadata[:start_at] != "0"
        Util::Repo.load(metadata)
      end

      book.run(run, metadata)
    end

    def additional_metadata
      {
        layout_panes: {},
        repo: {},
      }
    end
  end
end
