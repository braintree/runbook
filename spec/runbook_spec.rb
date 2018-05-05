require "spec_helper"

RSpec.describe Runbook do
  let(:title) { "Some Title" }
  let(:book) { Runbook.book(title) {} }

  it "has a version number" do
    expect(Runbook::VERSION).not_to be nil
  end

  describe "self.book" do
    it "returns a book" do
      expect(book).to be_a(Runbook::Entities::Book)
    end

    it "sets the books title" do
      expect(book.title).to eq(title)
    end

    it "evaluates the block in the context of the book's dsl" do
      in_book = nil
      out_book = Runbook.book(title) { in_book = self }
      expect(in_book).to eq(out_book.dsl)
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

    it "evaluates the block in the context of the section's dsl" do
      in_section = nil
      out_section = Runbook.section(title) { in_section = self }
      expect(in_section).to eq(out_section.dsl)
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

    it "evaluates the block in the context of the step's dsl" do
      in_step = nil
      out_step = Runbook.step(title) { in_step = self }
      expect(in_step).to eq(out_step.dsl)
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
  describe "self.books" do
    it "persists a set of books" do
      Runbook.books[:my_book] = book
      expect(Runbook.books[:my_book]).to eq(book)
    end
  end
end
