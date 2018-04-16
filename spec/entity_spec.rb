require "spec_helper"

RSpec.describe Runbook::Entity do
  let(:title) { "Some Title" }
  let(:entity) { Runbook::Entity.new(title) }

  it "has a title" do
    expect(entity.title).to eq(title)
  end

  describe "#items" do
    it "returns an empty array" do
      expect(entity.items).to eq([])
    end

    it "persists its value" do
      items = entity.items
      expect(entity.items).to equal(items)
    end
  end
end

