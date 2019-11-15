#!/usr/bin/env ruby
require "runbook"

runbook = Runbook.book "Example Layout Book" do
  description <<-DESC
This is a runbook for playing with the layout statement
  DESC

  layout [[
    [:runbook, :deploy],
    [:monitor_1, :monitor_2, :monitor_3],
  ]]

  section "Layout Testing" do
    step do
      tmux_command "echo 'Layouts Rock!'", :deploy
      note "Layouts are cool!"
    end
  end
end

if __FILE__ == $0
  Runbook::Runner.new(runbook).run
else
  runbook
end
