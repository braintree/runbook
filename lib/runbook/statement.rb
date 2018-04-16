module Runbook
  class Statement
    def render(view, output)
      view.render_before(self, output)
    end
  end
end
