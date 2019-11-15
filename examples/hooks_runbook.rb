#!/usr/bin/env ruby
require "runbook"

Runbook::Runs::SSHKit.register_hook(
  :output_before_hook,
  :before,
  Object
) do |object, metadata|
  location = "#{object.class}: #{metadata[:position]}"
  metadata[:toolbox].output " [Before: #{location}]\n"
end

Runbook::Runs::SSHKit.register_hook(
  :output_around_hook,
  :around,
  Object
) do |object, metadata, block|
  location = "#{object.class}: #{metadata[:position]}"
  metadata[:toolbox].output "  [Around_before: #{location}]\n"
  block.call(object, metadata)
  metadata[:toolbox].output "  [Around_after: #{location}]\n"
end

Runbook::Runs::SSHKit.register_hook(
  :output_after_hook,
  :after,
  Object
) do |object, metadata|
  location = "#{object.class}: #{metadata[:position]}"
  metadata[:toolbox].output " [After: #{location}]\n"
end

runbook = Runbook.book "Example Hooks Runbook" do
  description <<-DESC
This is a runbook for playing with runbook hooks
  DESC

  layout [[
    :runbook,
    :bottom,
  ]]

  section "Hook" do
    step do
      note "Looky, Looky, I got a hooky"
    end

    step
  end

  section "Fishing Hooks" do
    step do
      note "Hooked, line, and sinker"
    end

    step
  end

  section "Hooked on Phonics" do
    step do
      note "Huked on Phoonics reely werx 4 mee"
    end

    step
  end
end

if __FILE__ == $0
  Runbook::Runner.new(runbook).run
else
  runbook
end
