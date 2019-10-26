require "spec_helper"
require "entities/step_behavior"

RSpec.describe Runbook::Entities::Step do
  let(:title) { "Some Title" }
  let(:step) { Runbook::Entities::Step.new(title) }

  it "has a title" do
    expect(step.title).to eq(title)
  end

  it "does not require arguments" do
    expect(Runbook::Entities::Step.new).to be_a(Runbook::Entities::Step)
  end

  complex_arg_statements = ["ask", "ruby_command", "capture", "capture_all", "tmux_command", "upload"]
  statements = Runbook.statements.map do |klass|
    klass.to_s.split("::")[-1].underscore
  end

  include_examples "has add behavior", Runbook::Entities::Step
  include_examples "has ssh_config behavior", Runbook::Entities::Step
  include_examples "has nested statements", Runbook::Entities::Step
end
