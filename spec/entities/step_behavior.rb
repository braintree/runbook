RSpec.shared_examples "has nested statements" do |entity_class|
  let(:entity) { entity_class.new }

  complex_arg_statements = ["ask", "ruby_command", "capture", "capture_all", "tmux_command", "upload"]
  statements = Runbook.statements.map do |klass|
    klass.to_s.split("::")[-1].underscore
  end

  (statements - complex_arg_statements).each do |method|
    it "responds to the #{method} statement" do
      expect(entity).to respond_to(method)
    end

    describe "##{method}" do
      it "initializes a #{method} object" do
        statement = entity.send(method.to_sym, "some_arg")
        klass = "Runbook::Statements::#{method.camelize}".constantize
        expect(statement).to be_a(klass)
      end

      it "adds a #{method} statement to the entity's items" do
        statement = entity.send(method.to_sym, "some_arg")
        expect(entity.items).to include(statement)
      end
    end
  end

  it "adds itself as the new statement's parent" do
    stmt = entity.command("echo 'hi'")
    expect(stmt.parent).to eq(entity)
  end

  it "adds new statements to the entity's existing items" do
    stmt1 = entity.command("echo 'hi'")
    stmt2 = entity.command("echo 'hi'")
    expect(entity.items).to eq([stmt1, stmt2])
  end

  it "does not break method_missing" do
    expect { entity.bogus }.to raise_error(NameError)
  end

  it "does not respond to bogus methods" do
    expect(entity).to_not respond_to("bogus")
  end
end

RSpec.shared_examples "has ssh_config behavior" do |entity_class|
  let(:entity) { entity_class.new }

  describe "#parallelization" do
    let(:strategy) { :parallel }
    let(:limit) { 5 }
    let(:wait) { 2 }

    it "sets the parallelization strategy for the entity" do
      entity.parallelization(strategy: strategy)
      expect(entity.ssh_config[:parallelization]).to include(
        strategy: strategy,
      )
    end

    it "takes an optional limit in servers per group" do
      entity.parallelization(strategy: :groups, limit: limit)
      expect(entity.ssh_config[:parallelization]).to include(
        strategy: :groups,
        limit: limit,
      )
    end

    it "takes an optional wait time between runs in seconds" do
      entity.parallelization(strategy: :sequence, wait: wait)
      expect(entity.ssh_config[:parallelization]).to include(
        strategy: :sequence,
        wait: wait,
      )
    end
  end

  describe "#server" do
    let(:server) { "some_host.stg" }
    let(:old_server) { "some_host.stg" }

    it "sets the servers on the entity" do
      entity.server(server)
      expect(entity.ssh_config[:servers]).to eq([server])
    end

    it "explicitly sets the list of servers" do
      entity.server(old_server)
      entity.server(server)
      expect(entity.ssh_config[:servers]).to eq([server])
    end
  end

  describe "#servers" do
    let(:old_server) { "some_host.stg" }
    let(:servers) { ["some_host.stg", "other_server.stg"] }

    it "sets the servers on the entity" do
      entity.servers(*servers)
      expect(entity.ssh_config[:servers]).to eq(servers)
    end

    it "takes an array as a list of servers" do
      entity.servers(servers)
      expect(entity.ssh_config[:servers]).to eq(servers)
    end

    it "explicitly sets the list of servers" do
      entity.server(old_server)
      entity.servers(*servers)
      expect(entity.ssh_config[:servers]).to eq(servers)
    end
  end

  describe "#path" do
    let(:path) { "/some/path" }

    it "sets the remote path for the entity" do
      entity.path(path)
      expect(entity.ssh_config[:path]).to eq(path)
    end
  end

  describe "#user" do
    let(:user) { "root" }

    it "sets the remote user for the entity" do
      entity.user(user)
      expect(entity.ssh_config[:user]).to eq(user)
    end
  end

  describe "#group" do
    let(:group) { "root" }

    it "sets the remote group for the entity" do
      entity.group(group)
      expect(entity.ssh_config[:group]).to eq(group)
    end
  end

  describe "#env" do
    let(:env) { {rails_env: "production"} }

    it "sets the remote environment for the entity" do
      entity.env(env)
      expect(entity.ssh_config[:env]).to eq(env)
    end
  end

  describe "#umask" do
    let(:umask) { "077" }

    it "sets the remote umask for the entity" do
      entity.umask(umask)
      expect(entity.ssh_config[:umask]).to eq(umask)
    end
  end

  describe "#ssh_config" do
    let(:umask) { "077" }

    it "returns a configured ssh_config object" do
      ssh_config = entity.dsl.ssh_config do
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

RSpec.shared_examples "has add behavior" do |entity_class|
  let(:entity) { entity_class.new }

  describe "#add" do
    let(:note) { Runbook::Statements::Note.new("Read me") }

    it "adds a statement to the entity" do
      entity.dsl.add(note)
      expect(entity.items).to include(note)
    end

    it "adds itself as the statement's parent" do
      entity.dsl.add(note)
      expect(note.parent).to eq(entity)
    end
  end
end
