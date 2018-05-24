require "spec_helper"

RSpec.describe Runbook::Toolbox do
  let(:prompt) { instance_double("TTY::Prompt") }
  let(:toolbox) { Runbook::Toolbox.new }
  let(:msg) { "Something I want to say" }
  let(:default) { "default" }
  let(:choices) { [
    { key: "y", name: "Yes", value: true },
  ] }

  before(:each) do
    allow(TTY::Prompt).to receive(:new).and_return(prompt)
  end

  describe "initialize" do
    it "assigns a TTY::Prompt to prompt" do
      expect(toolbox.prompt).to eq(prompt)
    end
  end

  describe "ask" do
    it "passes its argument to prompt.ask" do
      expect(prompt).to receive(:ask).with(msg, default: nil)
      toolbox.ask(msg)
    end

    it "passes its default to prompt.ask" do
      expect(prompt).to receive(:ask).with(msg, default: default)
      toolbox.ask(msg, default: default)
    end
  end

  describe "expand" do
    it "passes its argument to prompt.ask" do
      expect(prompt).to receive(:expand).with(msg, choices)
      toolbox.expand(msg, choices)
    end
  end

  describe "yes?" do
    it "passes its argument to prompt.yes?" do
      expect(prompt).to receive(:yes?).with(msg)
      toolbox.yes?(msg)
    end
  end
  describe "output" do
    it "passes its argument to prompt.say" do
      expect(prompt).to receive(:say).with(msg)
      toolbox.output(msg)
    end
  end

  describe "warn" do
    it "passes its argument to prompt.warn" do
      expect(prompt).to receive(:warn).with(msg)
      toolbox.warn(msg)
    end
  end

  describe "error" do
    it "passes its argument to prompt.error" do
      expect(prompt).to receive(:error).with(msg)
      toolbox.error(msg)
    end
  end
end
