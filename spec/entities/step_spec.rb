require "spec_helper"
require "entities/step_behavior"

RSpec.describe Runbook::Entities::Step do
  let(:title) { "Some Title" }
  let(:step) { Runbook::Entities::Step.new(title) }

  it "has a title" do
    expect(step.title).to eq(title)
  end

  context "with tags" do
    let(:tags) { [:suse] }
    let(:step) { Runbook::Entities::Step.new(title, tags: tags) }

    it "has tags" do
      expect(step.tags).to eq(tags)
    end
  end

  context "with labels" do
    let(:labels) { {env: :staging} }
    let(:step) { Runbook::Entities::Step.new(title, labels: labels) }

    it "has labels" do
      expect(step.labels).to eq(labels)
    end
  end

  it "does not require arguments" do
    expect(Runbook::Entities::Step.new).to be_a(Runbook::Entities::Step)
  end

  include_examples "has add behavior", Runbook::Entities::Step
  include_examples "has ssh_config behavior", Runbook::Entities::Step
  include_examples "has nested statements", Runbook::Entities::Step
end
