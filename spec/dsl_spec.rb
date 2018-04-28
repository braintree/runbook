require "spec_helper"

RSpec.describe Runbook::DSL do
  describe "self.class" do
    let (:parent) { Object.new }
    let (:dsl) { Runbook::DSL.class.new(parent) }

    it "returns a class" do
      expect(Runbook::DSL.class).to be_a(Class)
    end

    it "returns a class that is initialized with a parent" do
      expect(dsl.parent).to eq(parent)
    end

    it "prepends modules passed as arguments" do
      mod = Module.new do
        def parent
          raise "new parent method error"
        end
      end

      dsl = Runbook::DSL.class(mod).new(parent)
      expect { dsl.parent }.to raise_error("new parent method error")
    end
  end
end
