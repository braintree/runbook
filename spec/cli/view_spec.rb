require "spec_helper"

RSpec.describe "runbook view", type: :aruba do
  let(:runbook_file) { "my_runbook.rb" }
  let(:content) do
    <<-RUNBOOK
    Runbook.book "My Runbook" do
      section "First Section" do
        step "Print stuff" do
          command "echo 'hi'"
        end
      end
    end
    RUNBOOK
  end

  before(:each) { write_file(runbook_file, content) }
  before(:each) { run(command) }

  describe "input specification" do
    context "runbook is written to standard in" do
      let(:command) { "sh -c 'cat #{runbook_file} | runbook view'" }

      it "prints a markdown representation of the runbook"
    end

    context "runbook is passed as an argument" do
      let(:command) { "runbook view #{runbook_file}" }

      it "prints a markdown representation of the runbook" do
        expect(last_command_started).to have_output(/echo 'hi'/)
      end
    end

    context "when a non-existant file is passed in as an argument" do
      it "prints a markdown representation of the runbook"
    end

    context "when a file option is passed in" do
      it "prints a markdown representation of the runbook"
    end

    context "when a non-existant file is passed in as an option" do
      it "prints a markdown representation of the runbook"
    end

    context "when input is specified as ruby" do
      it "reads the file as a ruby file"
    end

    context "when input is specified as unknown" do
      it "prints an unknown input format message"
    end
  end

  describe "output specification" do
    context "when output is specified as markdown" do
      it "prints a markdown representation of the runbook"
    end

    context "when output is specified as unknown" do
      it "prints an unknown output format message"
    end
  end
end
