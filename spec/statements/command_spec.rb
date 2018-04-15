require "spec_helper"

RSpec.describe Runbook::Statements::Command do
  let(:cmd) { "echo 'hi'" }
  let(:command) { Runbook::Statements::Command.new(cmd) }

  it "has a command" do
    expect(command.cmd).to eq(cmd)
  end
end
