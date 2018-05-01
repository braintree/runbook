require "spec_helper"

RSpec.describe Runbook::Entities::Step do
  let(:title) { "Some Title" }
  let(:step) { Runbook::Entities::Step.new(title) }

  it "has a title" do
    expect(step.title).to eq(title)
  end

  it "does not require arguments" do
    expect(Runbook::Entities::Step.new).to be_a(Runbook::Entities::Step)
  end

  complex_arg_statements = ["ask", "monitor", "ruby_command"]
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

  describe "#parallelization" do
    let(:strategy) { :parallel }
    let(:limit) { 5 }
    let(:wait) { 2 }

    it "sets the parallelization strategy for the step" do
      step.parallelization(strategy: strategy)
      expect(step.ssh_config[:parallelization]).to include(
        strategy: strategy,
      )
    end

    it "takes an optional limit in servers per group" do
      step.parallelization(strategy: :groups, limit: limit)
      expect(step.ssh_config[:parallelization]).to include(
        strategy: :groups,
        limit: limit,
      )
    end

    it "takes an optional wait time between runs in seconds" do
      step.parallelization(strategy: :sequence, wait: wait)
      expect(step.ssh_config[:parallelization]).to include(
        strategy: :sequence,
        wait: wait,
      )
    end
  end

  describe "#server" do
    let(:server) { "some_host.stg" }
    let(:old_server) { "some_host.stg" }

    it "sets the servers on the step" do
      step.server(server)
      expect(step.ssh_config[:servers]).to eq([server])
    end

    it "explicitly sets the list of servers" do
      step.server(old_server)
      step.server(server)
      expect(step.ssh_config[:servers]).to eq([server])
    end
  end

  describe "#servers" do
    let(:old_server) { "some_host.stg" }
    let(:servers) { ["some_host.stg", "other_server.stg"] }

    it "sets the servers on the step" do
      step.servers(*servers)
      expect(step.ssh_config[:servers]).to eq(servers)
    end

    it "takes an array as a list of servers" do
      step.servers(servers)
      expect(step.ssh_config[:servers]).to eq(servers)
    end

    it "explicitly sets the list of servers" do
      step.server(old_server)
      step.servers(*servers)
      expect(step.ssh_config[:servers]).to eq(servers)
    end
  end

  describe "#path" do
    let(:path) { "/some/path" }

    it "sets the remote path for the step" do
      step.path(path)
      expect(step.ssh_config[:path]).to eq(path)
    end
  end

  describe "#user" do
    let(:user) { "root" }

    it "sets the remote user for the step" do
      step.user(user)
      expect(step.ssh_config[:user]).to eq(user)
    end
  end

  describe "#group" do
    let(:group) { "root" }

    it "sets the remote group for the step" do
      step.group(group)
      expect(step.ssh_config[:group]).to eq(group)
    end
  end

  describe "#env" do
    let(:env) { {rails_env: "production"} }

    it "sets the remote environment for the step" do
      step.env(env)
      expect(step.ssh_config[:env]).to eq(env)
    end
  end

  describe "#umask" do
    let(:umask) { "077" }

    it "sets the remote umask for the step" do
      step.umask(umask)
      expect(step.ssh_config[:umask]).to eq(umask)
    end
  end

  describe "#ssh_config" do
    let(:umask) { "077" }

    it "returns a configured ssh_config object" do
      ssh_config = step.dsl.ssh_config do
        parallelization strategy: :sequence, wait: 5
        server "s1.prod"
        path "/home"
        user "root"
        group "root"
        env({path: "/usr/bin"})
        umask "077"
      end

      expect(ssh_config).to eq(
        {
          parallelization: {strategy: :sequence, limit: 2, wait: 5},
          servers: ["s1.prod"],
          path: "/home",
          user: "root",
          group: "root",
          env: {path: "/usr/bin"},
          umask: "077",
        }
      )
    end
  end
end
