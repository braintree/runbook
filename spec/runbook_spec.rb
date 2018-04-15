require "spec_helper"

RSpec.describe Runbook do
  it "has a version number" do
    expect(Runbook::VERSION).not_to be nil
  end

  describe "self.book" do
    let(:title) { "Some Title" }
    let(:book) { Runbook.book(title) {} }

    it "returns a book" do
      expect(book).to be_a(Runbook::Book)
    end

    it "sets the books title" do
      expect(book.title).to eq(title)
    end

    it "evaluates the block in the context of the book" do
      in_book = nil
      out_book = Runbook.book(title) { in_book = self }
      expect(in_book).to eq(out_book)
    end
  end
end
