module Runbook
  class Statement
    include Runbook::Hooks::Invoker

    attr_accessor :parent

    def render(view, output, metadata)
      invoke_with_hooks(view, self, output, metadata) do
        view.render(self, output, metadata)
      end
    end

    def run(run, metadata)
      invoke_with_hooks(run, self, metadata) do
        run.execute(self, metadata)
      end
    end
  end
end
