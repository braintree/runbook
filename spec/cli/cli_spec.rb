require "spec_helper"

RSpec.describe "runbook", type: :aruba do
  let(:command) { "runbook" }

  before(:each) { run_command(command) }

  context "no arguments are given" do
    it "prints out a help message" do
      expect(last_command_started).to have_output(/Commands:/)
      expect(last_command_started).to have_output(/runbook help \[COMMAND\]/)
    end
  end

  describe "help" do
    let(:command) { "runbook help" }

    it "prints out a help message" do
      expect(last_command_started).to have_output(/Commands:/)
      expect(last_command_started).to have_output(/runbook help \[COMMAND\]/)
    end

    it "reports a zero status code" do
      expect(last_command_stopped.exit_status).to eq(0)
    end
  end

  describe "help flag" do
    let(:command) { "runbook -h" }

    it "prints out a help message" do
      expect(last_command_started).to have_output(/Commands:/)
      expect(last_command_started).to have_output(/runbook help \[COMMAND\]/)
    end
  end

  describe "unknown command" do
    let(:command) { "runbook unknown" }

    it "prints out unknown command message" do
      expect(last_command_started).to have_output(%q{Could not find command "unknown".})
    end

    it "reports an error status code" do
      expect(last_command_stopped.exit_status).to eq(1)
    end
  end

  context "--version is passed" do
    let(:command) { "runbook --version" }
    let(:version) { Runbook::VERSION }

    it "prints out the version" do
      expect(last_command_started).to have_output(/Runbook v#{version}/)
    end
  end

end
