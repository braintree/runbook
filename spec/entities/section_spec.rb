require "spec_helper"

RSpec.describe Runbook::Entities::Section do
  let(:title) { "Some Title" }
  let(:section) { Runbook::Entities::Section.new(title) }

  it "has a title" do
    expect(section.title).to eq(title)
  end

  context "with tags" do
    let(:tags) { [:suse] }
    let(:section) { Runbook::Entities::Section.new(title, tags: tags) }

    it "has tags" do
      expect(section.tags).to eq(tags)
    end
  end

  context "with labels" do
    let(:labels) { {env: :staging} }
    let(:section) { Runbook::Entities::Section.new(title, labels: labels) }

    it "has labels" do
      expect(section.labels).to eq(labels)
    end
  end

  describe "#section" do
    it "adds a section to the section's items" do
      section2 = section.section("My Nested Section") {}
      expect(section.items).to include(section2)
    end

    it "adds itself as the new section's parent" do
      section2 = section.section("My Nested Section") {}
      expect(section2.parent).to eq(section)
    end

    it "adds to the section's existing items" do
      sec1 = section.section("My nested section 1") {}
      sec2 = section.section("My nested section 2") {}
      expect(section.items).to eq([sec1, sec2])
    end

    it "evaluates the block in the context of the section's dsl" do
      in_section = nil
      out_section = section.section("My inner section") {
        in_section = self
      }
      expect(in_section).to eq(out_section.dsl)
    end
  end

  describe "#step" do
    it "adds a step to the section's items" do
      step = section.step("My Step") {}
      expect(section.items).to include(step)
    end

    it "adds itself as the new step's parent" do
      step = section.step("My Step") {}
      expect(step.parent).to eq(section)
    end

    it "adds to the section's existing items" do
      step1 = section.step("My step") {}
      step2 = section.step("My other step") {}
      expect(section.items).to eq([step1, step2])
    end

    it "evaluates the block in the context of the step's dsl" do
      in_step = nil
      step = section.step("My step") { in_step = self }
      expect(in_step).to eq(step.dsl)
    end

    it "does not require a title" do
      expect((section.step {}).title).to be_nil
    end

    it "does not require a block" do
      expect(section.step("Some step")).to_not be_nil
    end
  end

  describe "#description" do
    it "adds a description to the section's items" do
      desc = section.description("My Description") {}
      expect(section.items).to include(desc)
    end

    it "adds itself as the new description's parent" do
      desc = section.description("My Description") {}
      expect(desc.parent).to eq(section)
    end

    it "adds to the section's existing items" do
      desc1 = section.description("My description") {}
      desc2 = section.description("My other description") {}
      expect(section.items).to eq([desc1, desc2])
    end
  end

  describe "#add" do
    let(:step) { Runbook.step("New step") {} }
    it "adds a step to the section" do
      section.dsl.add(step)
      expect(section.items).to include(step)
    end

    it "adds itself as the step's parent" do
      section.dsl.add(step)
      expect(step.parent).to eq(section)
    end
  end

  describe "#parallelization" do
    let(:strategy) { :parallel }
    let(:limit) { 5 }
    let(:wait) { 2 }

    it "sets the parallelization strategy for the section" do
      section.parallelization(strategy: strategy)
      expect(section.ssh_config[:parallelization]).to include(
        strategy: strategy,
      )
    end

    it "takes an optional limit in servers per group" do
      section.parallelization(strategy: :groups, limit: limit)
      expect(section.ssh_config[:parallelization]).to include(
        strategy: :groups,
        limit: limit,
      )
    end

    it "takes an optional wait time between runs in seconds" do
      section.parallelization(strategy: :sequence, wait: wait)
      expect(section.ssh_config[:parallelization]).to include(
        strategy: :sequence,
        wait: wait,
      )
    end
  end

  describe "#server" do
    let(:server) { "some_host.stg" }
    let(:old_server) { "some_host.stg" }

    it "sets the servers on the section" do
      section.server(server)
      expect(section.ssh_config[:servers]).to eq([server])
    end

    it "explicitly sets the list of servers" do
      section.server(old_server)
      section.server(server)
      expect(section.ssh_config[:servers]).to eq([server])
    end
  end

  describe "#servers" do
    let(:old_server) { "some_host.stg" }
    let(:servers) { ["some_host.stg", "other_server.stg"] }

    it "sets the servers on the section" do
      section.servers(*servers)
      expect(section.ssh_config[:servers]).to eq(servers)
    end

    it "takes an array as a list of servers" do
      section.servers(servers)
      expect(section.ssh_config[:servers]).to eq(servers)
    end

    it "explicitly sets the list of servers" do
      section.server(old_server)
      section.servers(*servers)
      expect(section.ssh_config[:servers]).to eq(servers)
    end
  end

  describe "#path" do
    let(:path) { "/some/path" }

    it "sets the remote path for the section" do
      section.path(path)
      expect(section.ssh_config[:path]).to eq(path)
    end
  end

  describe "#user" do
    let(:user) { "root" }

    it "sets the remote user for the section" do
      section.user(user)
      expect(section.ssh_config[:user]).to eq(user)
    end
  end

  describe "#group" do
    let(:group) { "root" }

    it "sets the remote group for the section" do
      section.group(group)
      expect(section.ssh_config[:group]).to eq(group)
    end
  end

  describe "#env" do
    let(:env) { {rails_env: "production"} }

    it "sets the remote environment for the section" do
      section.env(env)
      expect(section.ssh_config[:env]).to eq(env)
    end
  end

  describe "#umask" do
    let(:umask) { "077" }

    it "sets the remote umask for the section" do
      section.umask(umask)
      expect(section.ssh_config[:umask]).to eq(umask)
    end
  end

  describe "#ssh_config" do
    let(:umask) { "077" }

    it "returns a configured ssh_config object" do
      ssh_config = section.dsl.ssh_config do
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
