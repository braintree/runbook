require "spec_helper"

RSpec.describe Runbook::Statements::Condition do
  let(:predicate) { -> { Time.now.hour > 9 } }
  let(:if_stmt) { -> { puts "Too late to do this op!"; exit } }
  let(:else_stmt) { -> { puts "Carry on!" } }
  let(:condition) do
    Runbook::Statements::Condition.new(
      predicate: predicate,
      if_stmt: if_stmt,
      else_stmt: else_stmt,
    )
  end

  it "has a predicate" do
    expect(condition.predicate).to eq(predicate)
  end

  it "has an if_stmt" do
    expect(condition.if_stmt).to eq(if_stmt)
  end

  it "has an else_stmt" do
    expect(condition.else_stmt).to eq(else_stmt)
  end

  it "sets defaults for else_stmt" do
    condition = Runbook::Statements::Condition.new(
      predicate: predicate,
      if_stmt: if_stmt,
    )
    expect(condition.else_stmt).to be_nil
  end
end
