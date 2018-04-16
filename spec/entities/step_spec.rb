require "spec_helper"

RSpec.describe Runbook::Entities::Step do
  let(:title) { "Some Title" }
  let(:step) { Runbook::Entities::Step.new(title) }

  it "has a title" do
    expect(step.title).to eq(title)
  end

  complex_arg_statements = ["ask", "condition", "monitor"]
  statements = Runbook.statements.map do |klass|
    klass.to_s.split("::")[-1].underscore
  end

  (statements - complex_arg_statements).each do |method|
    it "responds to the #{method} statement" do
      expect(step).to respond_to(method)
    end

    describe "##{method}" do
      it "initializes a #{method} object" do
        statement = step.send(method.to_sym, "some_arg")
        klass = "Runbook::Statements::#{method.camelize}".constantize
        expect(statement).to be_a(klass)
      end

      it "adds a #{method} statement to the step's items" do
        statement = step.send(method.to_sym, "some_arg")
        expect(step.items).to include(statement)
      end
    end
  end

  it "adds new statements to the step's existing items" do
    stmt1 = step.command("echo 'hi'")
    stmt2 = step.command("echo 'hi'")
    expect(step.items).to eq([stmt1, stmt2])
  end

  it "does not break method_missing" do
    expect { step.bogus }.to raise_error(NameError)
  end

  it "does not respond to bogus methods" do
    expect(step).to_not respond_to("bogus")
  end

  describe "#server" do
    let(:server) { "some_host.stg" }
    let(:old_server) { "some_host.stg" }

    it "sets the servers on the step" do
      step.server(server)
      expect(step.server_list).to eq([server])
    end

    it "explicitly sets the list of servers" do
      step.server(old_server)
      step.server(server)
      expect(step.server_list).to eq([server])
    end
  end

  describe "#servers" do
    let(:old_server) { "some_host.stg" }
    let(:servers) { ["some_host.stg", "other_server.stg"] }

    it "sets the servers on the step" do
      step.servers(servers)
      expect(step.server_list).to eq(servers)
    end

    it "explicitly sets the list of servers" do
      step.server(old_server)
      step.servers(servers)
      expect(step.server_list).to eq(servers)
    end
  end
end
