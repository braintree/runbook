#!/usr/bin/env ruby
require "runbook"

runbook = Runbook.book "Simple Book" do
  description <<-DESC
This is a simple runbook that does stuff
  DESC

  section "Parent Section" do
    section "First Section" do
      step "Step 1" do
        parallelization({strategy: :sequence})
        servers "pblesi@server01.stg", "pblesi@server02.stg"
				user "root"
				path "/home/pblesi"
        env rails_env: "development"
        umask "077"

        note "I like cheese"
        note "I also like carrots"
        command "echo I love cheese"
        command "whoami"
      end
    end

    section "Second Section" do
      step "Step 1" do
        notice "Some cheese is actually yellow plastic"
        ruby_command do |rb_cmd, metadata|
          metadata[:toolbox].output("I like cheese whiz!")
        end
      end
    end
  end
end

Runbook.books[:simple_runbook] = runbook

if __FILE__ == $0
  Runbook::Runner.new(runbook).run
else
  runbook
end
