require "spec_helper"

RSpec.describe Runbook::Statements::Command do
  let(:cmd) { "ps aux | grep unicorn" }
  let(:prompt) { "Has unicorn stopped running?" }
  let(:monitor) { Runbook::Statements::Monitor.new(cmd: cmd, prompt: prompt) }

  it "has a command" do
    expect(monitor.cmd).to eq(cmd)
  end

  it "has a prompt" do
    expect(monitor.prompt).to eq(prompt)
  end
end

