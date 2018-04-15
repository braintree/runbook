require "spec_helper"

RSpec.describe Runbook::Statements::Note do
  let(:msg) { "Display me!" }
  let(:note) { Runbook::Statements::Note.new(msg) }

  it "has a message" do
    expect(note.msg).to eq(msg)
  end
end
