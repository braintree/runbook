require "spec_helper"

RSpec.describe Runbook::Statements::Ask do
  let(:prompt) { "How much chocolate can you eat?" }
  let(:into) { :num_kisses }
  let(:default) { "7" }
  let(:echo) { true }
  let(:ask) {
    Runbook::Statements::Ask.new(
      prompt,
      into: into,
      default: default,
      echo: echo,
    )
  }

  it "has a prompt" do
    expect(ask.prompt).to eq(prompt)
  end

  it "has an into" do
    expect(ask.into).to eq(into)
  end

  it "has a default" do
    expect(ask.default).to eq(default)
  end

  it "has an echo" do
    expect(ask.echo).to eq(echo)
  end

  describe "default values" do
    let(:ask) { Runbook::Statements::Ask.new(prompt, into: into) }

    it "sets default for default" do
      expect(ask.default).to be_nil
    end

    it "sets echo for echo" do
      expect(ask.echo).to be_truthy
    end
  end
end
