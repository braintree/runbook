require "spec_helper"

RSpec.describe Runbook::Book do
  let(:title) { "Some Title" }
  let(:book) { Runbook::Book.new(title) }

  it "has a title" do
    expect(book.title).to eq(title)
  end

  describe "#section" do
    it "adds a section to the book" do
      section = book.section("My Section") {}
      expect(book.sections).to include(section)
    end

    it "adds to the book's existing sections" do
      section1 = book.section("My Section") {}
      section2 = book.section("My Other Section") {}
      expect(book.sections).to eq([section1, section2])
    end

    it "evaluates the block in the context of the section" do
      in_section = nil
      out_section = book.section("My Section") { in_section = self }
      expect(in_section).to eq(out_section)
    end
  end
end
