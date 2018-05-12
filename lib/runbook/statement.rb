module Runbook
  class Statement
    attr_accessor :parent

    def render(view, output, metadata)
      view.render(self, output, metadata)
    end

    def run(run, metadata)
      run.execute(self, metadata)
    end
  end
end
