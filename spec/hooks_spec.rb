require "spec_helper"

RSpec.describe Runbook::Hooks do
  subject { Class.new { extend Runbook::Hooks } }

  describe "register" do
    let(:name) { :my_before_hook }
    let(:type) { :before }
    let(:klass) { Runbook::Entities::Book }
    let(:block) { Proc.new {} }

    it "Adds a hook to the list of hooks" do
      subject.register_hook(name, type, klass, &block)

      expect(subject.hooks).to include(
        {name: name, type: type, klass: klass, block: block}
      )
    end
  end

  describe "hooks_for" do
    let(:block) { Proc.new {} }
    let (:hook_1) {
      {
        name: :hook_1,
        type: :before,
        klass: Runbook::Entities::Book,
        block: block,
      }
    }
    let (:hook_2) {
      {
        name: :hook_2,
        type: :before,
        klass: Runbook::Entity,
        block: block,
      }
    }
    let (:hook_3) {
      {
        name: :hook_3,
        type: :around,
        klass: Runbook::Statements::Note,
        block: block,
      }
    }
    let (:hook_4) {
      {
        name: :hook_4,
        type: :after,
        klass: Runbook::Statement,
        block: block,
      }
    }
    let(:hooks) { [hook_1, hook_2, hook_3, hook_4] }

    before(:each) do
      hooks.each do |hook|
        subject.register_hook(
          hook[:name], hook[:type], hook[:klass], &hook[:block]
        )
      end
    end

    it "returns a list of hooks of the specified type and class" do
      before_entity_hooks = subject.hooks_for(:before, Runbook::Entity)
      expect(before_entity_hooks).to include(hook_1, hook_2)
      expect(before_entity_hooks).to_not include(hook_3, hook_4)
    end
  end

  describe "invoke_with_hooks" do
    subject {
      Class.new {
        extend Runbook::Hooks

        def self.result
          @result ||= []
        end
      }
    }
    let(:object) {
      Class.new { include Runbook::Hooks::Invoker }.new
    }
    let (:hook_1) {
      {
        name: :hook_1,
        type: :before,
        klass: object.class,
        block: Proc.new { |object, metadata|
          result << "before hook_1"
        },
      }
    }
    let (:hook_2) {
      {
        name: :hook_2,
        type: :before,
        klass: object.class,
        block: Proc.new { |object, metadata|
          result << "before hook_2"
        },
      }
    }
    let (:hook_3) {
      {
        name: :hook_3,
        type: :around,
        klass: object.class,
        block: Proc.new { |object, metadata, block|
          result << "around before hook_3"
          block.call(object, metadata)
          result << "around after hook_3"

        },
      }
    }
    let (:hook_4) {
      {
        name: :hook_4,
        type: :around,
        klass: object.class,
        block: Proc.new { |object, metadata, block|
          result << "around before hook_4"
          block.call(object, metadata)
          result << "around after hook_4"

        },
      }
    }
    let (:hook_5) {
      {
        name: :hook_5,
        type: :after,
        klass: object.class,
        block: Proc.new { |object, metadata|
          result << "after hook_5"
        },
      }
    }
    let (:hook_6) {
      {
        name: :hook_6,
        type: :after,
        klass: object.class,
        block: Proc.new { |object, metadata|
          result << "after hook_6"
        },
      }
    }
    let(:hooks) {
      [hook_1, hook_2, hook_3, hook_4, hook_5, hook_6]
    }

    before(:each) do
      hooks.each do |hook|
        subject.register_hook(
          hook[:name], hook[:type], hook[:klass], &hook[:block]
        )
      end
    end

    it "invokes all hooks for the object" do
      expected_result = [
        "before hook_1",
        "before hook_2",
        "around before hook_3",
        "around before hook_4",
        "book method invoked",
        "around after hook_4",
        "around after hook_3",
        "after hook_5",
        "after hook_6",
      ]

      object.invoke_with_hooks(subject, object, {}) do
        subject.result << "book method invoked"
      end

      expect(subject.result).to eq(expected_result)
    end
  end
end
