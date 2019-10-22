require "spec_helper"
require "entities/step_behavior"

RSpec.describe Runbook::Entities::Setup do
  let(:setup) { Runbook::Entities::Setup.new }

  context "with tags" do
    let(:tags) { [:suse] }
    let(:setup) { Runbook::Entities::Setup.new(tags: tags) }

    it "has tags" do
      expect(setup.tags).to eq(tags)
    end
  end

  it "does not require arguments" do
    expect(Runbook::Entities::Setup.new).to be_a(Runbook::Entities::Setup)
  end

  include_examples "has add behavior", Runbook::Entities::Setup
  include_examples "has ssh_config behavior", Runbook::Entities::Setup
  include_examples "has nested statements", Runbook::Entities::Setup
end
