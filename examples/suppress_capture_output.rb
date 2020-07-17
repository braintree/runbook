#!/usr/bin/env ruby
require "runbook"

class QuietToolbox < Runbook::Toolbox
  def output(msg); end
  def warn(msg); end
  def error(msg); end
end

Runbook::Runs::SSHKit.register_hook(
  :set_suppress_statement_output_hook,
  :around,
  Runbook::Statement
) do |object, metadata, block|
  parent_entity = object.parent_entity
  toolbox = metadata[:toolbox]
  formatter = Runbook.config.ssh_kit.output
  if parent_entity.tags.include?(:suppress_statement_output) || parent_entity.labels[:suppress_statement_output]
    Runbook.config.ssh_kit.output = Runbook.config.ssh_kit.use_format(:blackhole)
    metadata[:toolbox] = QuietToolbox.new
  end
	block.call(object, metadata)
  Runbook.config.ssh_kit.output = formatter
  metadata[:toolbox] = toolbox
end

runbook = Runbook.book "Capture Output Suppression" do
  description <<-DESC
This is a runbook that suppresses capture output
  DESC

  section "Demo Output Capture" do
    step "Capturing output", :suppress_statement_output do
      capture "echo hi", into: :echo_output
    end

    step "Printing output" do
      ruby_command { notice echo_output }
    end
  end
end

if __FILE__ == $0
  Runbook::Runner.new(runbook).run
else
  runbook
end
