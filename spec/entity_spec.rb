require "spec_helper"

RSpec.describe Runbook::Entity do
  let(:title) { "Some Title" }
  let(:parent) { Runbook::Entity.new("Parent") }
  let(:entity) { Runbook::Entity.new(title) }

  it "has a title" do
    expect(entity.title).to eq(title)
  end

  it "has a parent" do
    expect(entity.parent).to be_nil
  end

  it "takes a parent as an argument" do
    entity = Runbook::Entity.new(title, parent: parent)
    expect(entity.parent).to eq(parent)
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

  describe "#add" do
    let(:other_title) { "Some Other Title" }
    let(:other_entity) { Runbook::Entity.new(other_title) }

    before(:each) { entity.add(other_entity) }

    it "adds the item to items" do
      expect(entity.items).to include(other_entity)
    end

    it "sets the parent on the item" do
      expect(other_entity.parent).to eq(entity)
    end
  end
end

