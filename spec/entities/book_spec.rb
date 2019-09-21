require "spec_helper"

RSpec.describe Runbook::Entities::Book do
  let(:title) { "Some Title" }
  let(:book) { Runbook::Entities::Book.new(title) }

  it "has a title" do
    expect(book.title).to eq(title)
  end

  describe "#section" do
    it "adds a section to the book's items" do
      section = book.section("My Section") {}
      expect(book.items).to include(section)
    end

    it "adds itself as the new section's parent" do
      section = book.section("My Section") {}
      expect(section.parent).to eq(book)
    end

    it "adds to the book's existing items" do
      section1 = book.section("My Section") {}
      section2 = book.section("My Other Section") {}
      expect(book.items).to eq([section1, section2])
    end

    it "evaluates the block in the context of the section's dsl" do
      in_section = nil
      section = book.section("My Section") { in_section = self }
      expect(in_section).to eq(section.dsl)
    end
  end

  describe "#step" do
    it "adds a step to the book's items" do
      step = book.step("My Step") {}
      expect(book.items).to include(step)
    end

    it "adds itself as the new step's parent" do
      step = book.step("My Step") {}
      expect(step.parent).to eq(book)
    end

    it "adds to the book's existing items" do
      step = book.step("My Step") {}
      section = book.section("My Section") {}
      expect(book.items).to eq([step, section])
    end

    it "evaluates the block in the context of the step's dsl" do
      in_step = nil
      step = book.step("My Step") { in_step = self }
      expect(in_step).to eq(step.dsl)
    end
  end

  describe "#description" do
    it "adds a description to the book's items" do
      desc = book.description("My Description")
      expect(book.items).to include(desc)
    end

    it "adds itself as the new description's parent" do
      desc = book.description("My Description")
      expect(desc.parent).to eq(book)
    end

    it "adds to the book's existing items" do
      desc1 = book.description("My description")
      desc2 = book.description("My other description")
      expect(book.items).to eq([desc1, desc2])
    end
  end

  describe "#layout" do
    it "adds a layout to the book's items" do
      layout = book.layout([])
      expect(book.items).to include(layout)
    end

    it "adds itself as the new layout's parent" do
      layout = book.layout([])
      expect(layout.parent).to eq(book)
    end

    it "adds to the book's existing items" do
      desc = book.description("My description")
      layout = book.layout([])
      expect(book.items).to eq([desc, layout])
    end
  end

  describe "#add" do
    let(:section) { Runbook.section("My Section") {} }

    it "adds a section to the book" do
      book.dsl.add(section)
      expect(book.items).to include(section)
    end

    it "adds itself as the section's parent" do
      book.dsl.add(section)
      expect(section.parent).to eq(book)
    end
  end

  describe "#parallelization" do
    let(:strategy) { :parallel }
    let(:limit) { 5 }
    let(:wait) { 2 }

    it "sets the parallelization strategy for the book" do
      book.parallelization(strategy: strategy)
      expect(book.ssh_config[:parallelization]).to include(
        strategy: strategy,
      )
    end

    it "takes an optional limit in servers per group" do
      book.parallelization(strategy: :groups, limit: limit)
      expect(book.ssh_config[:parallelization]).to include(
        strategy: :groups,
        limit: limit,
      )
    end

    it "takes an optional wait time between runs in seconds" do
      book.parallelization(strategy: :sequence, wait: wait)
      expect(book.ssh_config[:parallelization]).to include(
        strategy: :sequence,
        wait: wait,
      )
    end
  end

  describe "#server" do
    let(:server) { "some_host.stg" }
    let(:old_server) { "some_host.stg" }

    it "sets the servers on the book" do
      book.server(server)
      expect(book.ssh_config[:servers]).to eq([server])
    end

    it "explicitly sets the list of servers" do
      book.server(old_server)
      book.server(server)
      expect(book.ssh_config[:servers]).to eq([server])
    end
  end

  describe "#servers" do
    let(:old_server) { "some_host.stg" }
    let(:servers) { ["some_host.stg", "other_server.stg"] }

    it "sets the servers on the book" do
      book.servers(*servers)
      expect(book.ssh_config[:servers]).to eq(servers)
    end

    it "takes an array as a list of servers" do
      book.servers(servers)
      expect(book.ssh_config[:servers]).to eq(servers)
    end

    it "explicitly sets the list of servers" do
      book.server(old_server)
      book.servers(*servers)
      expect(book.ssh_config[:servers]).to eq(servers)
    end
  end

  describe "#path" do
    let(:path) { "/some/path" }

    it "sets the remote path for the book" do
      book.path(path)
      expect(book.ssh_config[:path]).to eq(path)
    end
  end

  describe "#user" do
    let(:user) { "root" }

    it "sets the remote user for the book" do
      book.user(user)
      expect(book.ssh_config[:user]).to eq(user)
    end
  end

  describe "#group" do
    let(:group) { "root" }

    it "sets the remote group for the book" do
      book.group(group)
      expect(book.ssh_config[:group]).to eq(group)
    end
  end

  describe "#env" do
    let(:env) { {rails_env: "production"} }

    it "sets the remote environment for the book" do
      book.env(env)
      expect(book.ssh_config[:env]).to eq(env)
    end
  end

  describe "#umask" do
    let(:umask) { "077" }

    it "sets the remote umask for the book" do
      book.umask(umask)
      expect(book.ssh_config[:umask]).to eq(umask)
    end
  end

  describe "#ssh_config" do
    let(:umask) { "077" }

    it "returns a configured ssh_config object" do
      ssh_config = book.dsl.ssh_config do
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
