require "spec_helper"

RSpec.describe "runbook view", type: :aruba do
  let(:config_file) { "runbook_config.rb" }
  let(:config_content) do
    <<-CONFIG
    Runbook.configure do |config|
      config.ssh_kit.use_format :dot
    end
    CONFIG
  end
  let(:runbook_file) { "my_runbook.rb" }
  let(:runbook_registration) {}
  let(:content) do
    <<-RUNBOOK
    runbook = Runbook.book "My Runbook" do
      section "First Section" do
        step "Print stuff" do
          command "echo 'hi'"
          ruby_command {}
        end
      end
    end
    #{runbook_registration}
    RUNBOOK
  end

  before(:each) { write_file(config_file, config_content) }
  before(:each) { write_file(runbook_file, content) }
  before(:each) { run_command(command) }

  describe "input specification" do
    context "runbook is passed as an argument" do
      let(:command) { "runbook view #{runbook_file}" }

      it "prints a markdown representation of the runbook" do
        expect(last_command_started).to have_output(/echo 'hi'/)
      end

      context "without runbook_registration" do
        let(:runbook_registration) {}

        it "does not render code blocks" do
          expect(last_command_started).to have_output(/Unable to retrieve source code/)
        end
      end

      context "with runbook_registration" do
        let(:runbook_registration) do
          "Runbook.books[:my_runbook] = runbook"
        end

        it "renders code blocks" do
          expect(last_command_started).to_not have_output(/Unable to retrieve source code/)
        end
      end
    end

    context "when an unknown file is passed in as an argument" do
      let(:command) { "runbook view unknown" }
      let(:unknown_file_output) {
        "view: cannot access unknown: No such file or directory"
      }

      it "prints an unknown file message" do
        expect(last_command_started).to have_output(unknown_file_output)
      end
    end

    context "when view is passed" do
      let(:command) { "runbook view --view markdown #{runbook_file}" }

      it "prints a markdown representation of the runbook" do
        expect(last_command_started).to have_output(/echo 'hi'/)
      end

      context "(when v is passed)" do
        let(:command) { "runbook view -v markdown #{runbook_file}" }

        it "prints a markdown representation of the runbook" do
          expect(last_command_started).to have_output(/echo 'hi'/)
        end
      end
    end

    context "when config is passed" do
      let(:command) { "runbook view --config #{config_file} #{runbook_file}" }

      it "prints the runbook using the specified configuration" do
        expect(last_command_started).to have_output(/echo 'hi'/)
      end

      context "(when c is passed)" do
        let(:command) { "runbook view -c #{config_file} #{runbook_file}" }

        it "prints the runbook using the specified configuration" do
          expect(last_command_started).to have_output(/echo 'hi'/)
        end
      end

      context "when config does not exist" do
        let(:command) { "runbook view --config unknown #{runbook_file}" }
        let(:unknown_file_output) {
          "view: cannot access unknown: No such file or directory"
        }

        it "prints an unknown file message" do
          expect(
            last_command_started
          ).to have_output(unknown_file_output)
        end
      end
    end
  end
end
