module Runbook
  class Statement
    def render(view, output)
      view.render(self, output)
    end
  end
end
