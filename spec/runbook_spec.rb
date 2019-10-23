require "spec_helper"

RSpec.describe Runbook do
  let(:title) { "Some Title" }
  let(:tags) { [:mutator, :redhat] }
  let(:labels) { {env: :prod, cloud_provider: :aws} }
  let(:book) { Runbook.book(title) {} }

  it "has a version number" do
    expect(Runbook::VERSION).not_to be nil
  end

  describe "self.book" do
    around(:each) do |example|
      begin
        example.run
      ensure
        Runbook.books.clear
      end
    end

    it "returns a book" do
      expect(book).to be_a(Runbook::Entities::Book)
    end

    it "sets the books title" do
      expect(book.title).to eq(title)
    end

    context "with tags" do
      let(:book) { Runbook.book(title, *tags) {} }

      it "sets the books tags" do
        expect(book.tags).to eq(tags)
      end
    end

    context "with labels" do
      let(:book) { Runbook.book(title, labels: labels) {} }

      it "sets the books labels" do
        expect(book.labels).to eq(labels)
      end
    end

    it "evaluates the block in the context of the book's dsl" do
      in_book = nil
      out_book = Runbook.book(title) { in_book = self }
      expect(in_book).to eq(out_book.dsl)
    end

    it "loads Runbook's configuration" do
      expect(Runbook::Configuration).to receive(:load_config)
      book
    end

    it "registers a book" do
      expect(Runbook.books).to eq([book])
    end
  end

  describe "self.section" do
    let(:section) { Runbook.section(title) {} }

    it "returns a section" do
      expect(section).to be_a(Runbook::Entities::Section)
    end

    it "sets the section's title" do
      expect(section.title).to eq(title)
    end

    context "with tags" do
      let(:section) { Runbook.section(title, *tags) {} }

      it "sets the sections tags" do
        expect(section.tags).to eq(tags)
      end
    end

    context "with labels" do
      let(:section) { Runbook.section(title, labels: labels) {} }

      it "sets the sections labels" do
        expect(section.labels).to eq(labels)
      end
    end

    it "evaluates the block in the context of the section's dsl" do
      in_section = nil
      out_section = Runbook.section(title) { in_section = self }
      expect(in_section).to eq(out_section.dsl)
    end

    it "loads Runbook's configuration" do
      expect(Runbook::Configuration).to receive(:load_config)
      section
    end
  end

  describe "self.setup" do
    let(:setup) { Runbook.setup {} }

    it "returns a setup" do
      expect(setup).to be_a(Runbook::Entities::Setup)
    end

    it "sets the setup's title" do
      expect(setup.title).to eq("Setup")
    end

    context "with tags" do
      let(:setup) { Runbook.setup(*tags) {} }

      it "sets the setup's tags" do
        expect(setup.tags).to eq(tags)
      end
    end

    context "with labels" do
      let(:setup) { Runbook.setup(labels: labels) {} }

      it "sets the setup's labels" do
        expect(setup.tags).to eq([])
        expect(setup.labels).to eq(labels)
      end
    end

    it "evaluates the block in the context of the setup's dsl" do
      in_setup = nil
      out_setup = Runbook.setup { in_setup = self }
      expect(in_setup).to eq(out_setup.dsl)
    end

    it "loads Runbook's configuration" do
      expect(Runbook::Configuration).to receive(:load_config)
      setup
    end
  end

  describe "self.step" do
    let(:step) { Runbook.step(title) {} }

    it "returns a step" do
      expect(step).to be_a(Runbook::Entities::Step)
    end

    it "sets the step's title" do
      expect(step.title).to eq(title)
    end

    context "with title and tags" do
      let(:step) { Runbook.step(title, *tags) {} }

      it "sets the steps tags" do
        expect(step.title).to eq(title)
        expect(step.tags).to eq(tags)
      end
    end

    context "with only tags" do
      let(:step) { Runbook.step(*tags) {} }

      it "sets the steps tags" do
        expect(step.title).to be_nil
        expect(step.tags).to eq(tags)
      end
    end

    context "with labels" do
      let(:step) { Runbook.step(labels: labels) {} }

      it "sets the steps labels" do
        expect(step.title).to be_nil
        expect(step.labels).to eq(labels)
      end
    end

    it "evaluates the block in the context of the step's dsl" do
      in_step = nil
      out_step = Runbook.step(title) { in_step = self }
      expect(in_step).to eq(out_step.dsl)
    end

    it "loads Runbook's configuration" do
      expect(Runbook::Configuration).to receive(:load_config)
      step
    end

    context "when no title is given" do
      let(:step) { Runbook.step {} }
      it "title returns nil" do
        expect(step.title).to be_nil
      end
    end

    context "when no block is given" do
      let(:step) { Runbook.step(title) }
      it "does not error" do
        expect(step).to_not be_nil
      end
    end
  end

  describe "self.register" do
    around(:each) do |example|
      begin
        example.run
      ensure
        Runbook.books.clear
      end
    end

    it "registers a book" do
      book
      Runbook.books.clear
      Runbook.register(book)
      expect(Runbook.books).to eq([book])
    end
  end

  describe "self.books" do
    around(:each) do |example|
      begin
        example.run
      ensure
        Runbook.books.clear
      end
    end

    it "persists a list of books" do
      book
      Runbook.books.clear
      Runbook.books << book
      expect(Runbook.books).to eq([book])
    end
  end

  describe "self.deprecator" do
    it "returns an ActiveSupport::Deprecation object" do
      expect(Runbook.deprecator).to be_a(ActiveSupport::Deprecation)
    end

    it "is memoized" do
      deprecator1 = Runbook.deprecator
      deprecator2 = Runbook.deprecator
      expect(deprecator2.object_id).to eq(deprecator1.object_id)
    end

    it "states the function will be replaced in the next major version" do
      nmv = Runbook::VERSION.split(".").first.to_i + 1
      expect(STDERR).to receive(:puts).with(/DEPRECATION WARNING:.*Runbook #{nmv}.0.*/)
      Runbook.deprecator.deprecation_warning(:deprecated_method, :new_method)
    end
  end
end
