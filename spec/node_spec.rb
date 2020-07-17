require "spec_helper"

RSpec.describe Runbook::Node do
  subject { Class.new(Runbook::Node) { def initialize(); end  }.new }

  describe "initialize" do
    it "cannot be initialized" do
      expect { Runbook::Node.new }.to raise_error("Should not be initialized")
    end
  end

  describe "dynamic?" do
    it "defaults to falsey" do
      expect(subject.dynamic?).to be_falsey
    end
  end

  describe "visited?" do
    it "defaults to falsey" do
      expect(subject.visited?).to be_falsey
    end
  end

  describe "dynamic!" do
    it "sets the node as a dynamic node" do
      subject.dynamic!
      expect(subject.dynamic?).to be_truthy
    end
  end

  describe "visited!" do
    it "marks the node as having been visited" do
      subject.visited!
      expect(subject.visited?).to be_truthy
    end
  end

  describe "parent_entity" do
    context "when node is an entity" do
      subject { Runbook::Entity.new("Title") }
      it "returns self" do
        expect(subject.parent_entity).to eq(subject)
      end
    end

    context "when node is statement" do
      context "when node's parent is nil" do
        subject { Class.new(Runbook::Statement) { def initialize(); end  }.new }

        it "returns nil" do
          expect(subject.parent_entity).to eq(nil)
        end
      end

      context "when node's parent is an entity" do
        let(:entity) { Runbook::Entity.new("Title") }
        let(:statement_class) do
          Class.new(Runbook::Statement) do
            def initialize(parent)
              @parent = parent
            end
          end
        end
        subject { statement_class.new(entity) }

        it "returns the node's parent" do
          expect(subject.parent_entity).to eq(entity)
        end
      end
    end
  end
end
