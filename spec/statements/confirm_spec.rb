require "spec_helper"

RSpec.describe Runbook::Statements::Confirm do
  let(:prompt) { "Ok to continue?" }
  let(:confirm) { Runbook::Statements::Confirm.new(prompt) }

  it "has a prompt" do
    expect(confirm.prompt).to eq(prompt)
  end
end

