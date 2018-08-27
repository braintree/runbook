module Runbook::Extensions
  module Tmux
    module LayoutDSL
      def layout(layout)
        Runbook::Statements::Layout.new(layout).tap do |layout|
          parent.add(layout)
        end
      end
    end

    module TmuxCommandDSL
      def tmux_command(cmd, pane)
        Runbook::Statements::TmuxCommand.new(cmd, pane).tap do |tmux_command|
          parent.add(tmux_command)
        end
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Tmux::LayoutDSL)
  Runbook::Entities::Step::DSL.prepend(Tmux::TmuxCommandDSL)
end
