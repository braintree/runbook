require "spec_helper"

RSpec.describe Runbook do
  it "has a version number" do
    expect(Runbook::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
