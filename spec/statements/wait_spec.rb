require "spec_helper"

RSpec.describe Runbook::Statements::Note do
  let(:time) { 120 }
  let(:wait) { Runbook::Statements::Wait.new(120) }

  it "has a wait time" do
    expect(wait.time).to eq(time)
  end
end
