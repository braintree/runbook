require "spec_helper"

RSpec.describe Runbook::Statements::Description do
  let(:msg) { "Display me!" }
  let(:description) { Runbook::Statements::Description.new(msg) }

  it "has a message" do
    expect(description.msg).to eq(msg)
  end
end
