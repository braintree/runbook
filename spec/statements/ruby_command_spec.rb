require "spec_helper"

RSpec.describe Runbook::Statements::RubyCommand do
  let(:block) { Proc.new {} }
  let(:ruby_command) { Runbook::Statements::RubyCommand.new(&block) }

  it "has a block" do
    expect(ruby_command.block).to eq(block)
  end
end
