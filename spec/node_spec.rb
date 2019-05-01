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
end
