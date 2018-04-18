module Runbook
  class Statement
    def render(view, output, metadata)
      view.render(self, output, metadata)
    end
  end
end
