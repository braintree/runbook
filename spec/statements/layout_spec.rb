require "spec_helper"

RSpec.describe Runbook::Statements::Layout do
  let(:structure) { [[:runbook, :deploy], [:mon1, :mon2]] }
  let(:layout) { Runbook::Statements::Layout.new(structure) }

  it "has a structure" do
    expect(layout.structure).to eq(structure)
  end
end
