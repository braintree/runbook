require "spec_helper"

RSpec.describe Runbook::Statements::Global do
  let(:globals) { [:global1, :global2] }
  let(:global) { Runbook::Statements::Global.new(*globals) }

  it "has a list of globals" do
    expect(global.globals).to eq(globals)
  end

  context "with a single global variable" do
    let(:globals) { :global }
    let(:global) { Runbook::Statements::Global.new(globals) }
    it "returns a list including that variable" do
      expect(global.globals).to eq([globals])
    end
  end
end
