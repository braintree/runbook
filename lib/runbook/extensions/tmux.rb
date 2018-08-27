module Runbook::Extensions
  module Tmux
    module LayoutDSL
      def layout(layout)
        Runbook::Statements::Layout.new(layout).tap do |layout|
          parent.add(layout)
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Tmux::LayoutDSL)
end
