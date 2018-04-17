require "spec_helper"

RSpec.describe Runbook::Viewer do
  let(:book) do
    Runbook.book "My Book" do
      section "First Section" do
        step "Step 1" do
          note "I like cheese"
        end
      end

      section "Second Section" do
        step "Step 1" do
          confirm "Did you eat cheese today?"
        end
      end
    end
  end
  let(:viewer) { Runbook::Viewer.new(book) }

  context "with markdown view" do
    let(:view) { :markdown }

    it "generates a markdown representation of the book" do
      markdown = viewer.generate(view)

      expect(markdown).to eq(<<-MARKDOWN)
# My Book

## 1. First Section

1. [] Step 1

   I like cheese

## 1. Second Section

1. [] Step 1

   confirm: Did you eat cheese today?

MARKDOWN
    end
  end
end
