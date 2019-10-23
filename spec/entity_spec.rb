require "spec_helper"

RSpec.describe Runbook::Entity do
  let(:title) { "Some Title" }
  let(:parent) { Runbook::Entity.new("Parent") }
  let(:tags) { [:skip, :mutator] }
  let(:labels) { {env: :prod, cloud_provider: :aws} }
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

  it "takes a list of tags as an argument" do
    entity = Runbook::Entity.new(title, tags: tags)
    expect(entity.tags).to eq(tags)
  end

  it "takes a set of labels as an argument" do
    entity = Runbook::Entity.new(title, labels: labels)
    expect(entity.labels).to eq(labels)
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

  describe "#dynamic" do
    it "marks the current entity as dynamic" do
      entity.dynamic!
      expect(entity.dynamic?).to be_truthy
    end

    it "marks the current entity's children as dynamic" do
      entity.add(Runbook::Entity.new(""))
      entity.add(Runbook::Entity.new(""))
      entity.dynamic!
      entity.items.each do |item|
        expect(item.dynamic?).to be_truthy
      end
    end

    it "marks the current entity's grand children as dynamic" do
      child = Runbook::Entity.new("")
      entity.add(child)
      child.add(Runbook::Entity.new(""))
      child.add(Runbook::Statements::Note.new("note"))
      entity.dynamic!
      child.items.each do |item|
        expect(item.dynamic?).to be_truthy
      end
    end
  end
end

