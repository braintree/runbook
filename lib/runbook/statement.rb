module Runbook
  class Statement < Node
    include Runbook::Hooks::Invoker

    def render(view, output, metadata)
      invoke_with_hooks(view, self, output, metadata) do
        view.render(self, output, metadata)
      end
    end

    def run(run, metadata)
      return if dynamic? && visited?

      invoke_with_hooks(run, self, metadata) do
        run.execute(self, metadata)
      end
      self.visited!
    end
  end
end
