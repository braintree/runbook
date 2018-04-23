require "spec_helper"

RSpec.describe Runbook::Statements::RubyCommand do
  let(:cmd) { Proc.new {} }
  let(:ruby_command) { Runbook::Statements::RubyCommand.new(cmd) }

  it "has a command" do
    expect(ruby_command.cmd).to eq(cmd)
  end
end
