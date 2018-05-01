module Runbook
  class Statement
    def render(view, output, metadata)
      view.render(self, output, metadata)
    end

    def run(run, metadata)
      run.execute(self, metadata)
    end
  end
end
