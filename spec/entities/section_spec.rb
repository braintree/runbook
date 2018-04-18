require "spec_helper"

RSpec.describe Runbook::Entities::Section do
  let(:title) { "Some Title" }
  let(:section) { Runbook::Entities::Section.new(title) }

  it "has a title" do
    expect(section.title).to eq(title)
  end

  describe "#step" do
    it "adds a step to the section's items" do
      step = section.step("My Step") {}
      expect(section.items).to include(step)
    end

    it "adds to the section's existing items" do
      step1 = section.step("My step") {}
      step2 = section.step("My other step") {}
      expect(section.items).to eq([step1, step2])
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

  describe "#description" do
    it "adds a description to the section's items" do
      desc = section.description("My Description") {}
      expect(section.items).to include(desc)
    end

    it "adds to the section's existing items" do
      desc1 = section.description("My description") {}
      desc2 = section.description("My other description") {}
      expect(section.items).to eq([desc1, desc2])
    end
  end
end
