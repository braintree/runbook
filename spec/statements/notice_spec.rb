require "spec_helper"

RSpec.describe Runbook::Statements::Notice do
  let(:msg) { "Potentialy dangerous, pay attention!" }
  let(:notice) { Runbook::Statements::Notice.new(msg) }

  it "has a message" do
    expect(notice.msg).to eq(msg)
  end
end
