require "spec_helper"

RSpec.describe Runbook::Statements::Ask do
  let(:prompt) { "How much chocolate can you eat?" }
  let(:into) { :num_kisses }
  let(:ask) { Runbook::Statements::Ask.new(prompt, into: into) }

  it "has a prompt" do
    expect(ask.prompt).to eq(prompt)
  end

  it "has an into" do
    expect(ask.into).to eq(into)
  end
end
