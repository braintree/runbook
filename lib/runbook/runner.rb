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
      metadata = {
        noop: noop,
        auto: auto,
        paranoid: paranoid,
        start_at: start_at,
        toolbox: toolbox,
        layout_panes: {},
      }.merge(Runbook::Entities::Book.initial_run_metadata)

      book.run(run, metadata)
    end
  end
end
