require "spec_helper"

RSpec.describe Runbook::Section do
  let(:title) { "Some Title" }
  let(:section) { Runbook::Section.new(title) }

  it "has a title" do
    expect(section.title).to eq(title)
  end

  describe "#step" do
    it "adds a step to the section" do
      step = section.step("My Step") {}
      expect(section.steps).to include(step)
    end

    it "adds to the section's existing steps" do
      step1 = section.step("My step") {}
      step2 = section.step("My other step") {}
      expect(section.steps).to eq([step1, step2])
    end

    it "evaluates the block in the context of the step" do
      in_step = nil
      out_step = section.step("My step") { in_step = self }
      expect(in_step).to eq(out_step)
    end

    it "does not require a title" do
      expect((section.step {}).title).to be_nil
    end

    it "does not require a block" do
      expect(section.step("Some step")).to_not be_nil
    end
  end
end
