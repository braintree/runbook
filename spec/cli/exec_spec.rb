require "spec_helper"

RSpec.describe "runbook run", type: :aruba do
  let(:runbook_file) { "my_runbook.rb" }
  let(:runbook_registration) {}
  let(:content) do
    <<-RUNBOOK
    Runbook.book "My Runbook" do
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

  before(:each) { write_file(runbook_file, content) }
  before(:each) { run(command) }

  describe "input specification" do
    context "runbook is passed as an argument" do
      let(:command) { "runbook exec #{runbook_file}" }
      let(:output_lines) {
        [
          /Executing My Runbook\.\.\./,
          /Section 1: First Section/,
          /Step 1\.1: Print stuff/,
          /.*echo 'hi'.*/,
        ]
      }

      it "executes the runbook" do
        output_lines.each do |line|
          expect(last_command_started).to have_output(line)
        end
      end
    end

    context "when an unknown file is passed in as an argument" do
      let(:command) { "runbook exec unknown" }
      let(:unknown_file_output) {
        "exec: cannot access unknown: No such file or directory"
      }

      it "prints an unknown file message" do
        expect(last_command_started).to have_output(unknown_file_output)
      end
    end

    context "when noop is passed" do
      let(:command) { "runbook exec --noop #{runbook_file}" }
      let(:output_lines) {
        [
          /Executing My Runbook\.\.\./,
          /Section 1: First Section/,
          /Step 1\.1: Print stuff/,
          /.*\[NOOP\] Run: `echo 'hi'`.*/,
        ]
      }

      it "noops the runbook" do
        output_lines.each do |line|
          expect(last_command_started).to have_output(line)
        end
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

      context "(when n is passed)" do
        let(:command) { "runbook exec -n #{runbook_file}" }

        it "noops the runbook" do
          output_lines.each do |line|
            expect(last_command_started).to have_output(line)
          end
        end
      end
    end

    context "when auto is passed" do
      let(:command) { "runbook exec --auto #{runbook_file}" }
      let(:content) do
        <<-RUNBOOK
        Runbook.book "My Runbook" do
          section "First Section" do
            step "Ask stuff" do
              confirm "You sure?"
            end
          end
        end
        RUNBOOK
      end
      let(:output_lines) {
        [
          /Executing My Runbook\.\.\./,
          /Section 1: First Section/,
          /Step 1\.1: Ask stuff/,
          /.*Skipping confirmation \(auto\): You sure\?.*/,
        ]
      }

      it "does not prompt" do
        output_lines.each do |line|
          expect(last_command_started).to have_output(line)
        end
      end

      context "(when a is passed)" do
        let(:command) { "runbook exec -a #{runbook_file}" }

        it "does not prompt" do
          output_lines.each do |line|
            expect(last_command_started).to have_output(line)
          end
        end
      end
    end

    context "when start_at is passed" do
      let(:command) { "runbook exec --start-at 1.2 #{runbook_file}" }
      let(:content) do
        <<-RUNBOOK
        Runbook.book "My Runbook" do
          section "First Section" do
            step "Skip me!" do
              note "fish"
            end

            step "Run me" do
              note "carrots"
            end

            step "Run me" do
              note "peas"
            end
          end
        end
        RUNBOOK
      end
      let(:output_lines) {
        [
          /Executing My Runbook\.\.\./,
          /Step 1\.2: Run me/,
          /carrots/,
          /Step 1\.3: Run me/,
          /peas/,
        ]
      }
      let(:non_output_lines) {
        [
          /Section 1: First Section/,
          /Skip me/,
          /fish/,
        ]
      }

      it "starts at the specified position" do
        output_lines.each do |line|
          expect(last_command_started).to have_output(line)
        end
        non_output_lines.each do |line|
          expect(last_command_started).to_not have_output(line)
        end
      end

      context "(when s is passed)" do
        let(:command) { "runbook exec -s 1.2 #{runbook_file}" }

        it "starts at the specified position" do
          output_lines.each do |line|
            expect(last_command_started).to have_output(line)
          end
          non_output_lines.each do |line|
            expect(last_command_started).to_not have_output(line)
          end
        end
      end
    end

    context "when run is passed" do
      let(:command) { "runbook exec --run ssh_kit #{runbook_file}" }
      let(:output_lines) {
        [
          /Executing My Runbook\.\.\./,
          /Section 1: First Section/,
          /Step 1\.1: Print stuff/,
          /.*echo 'hi'.*/,
        ]
      }

      it "runs the runbook" do
        output_lines.each do |line|
          expect(last_command_started).to have_output(line)
        end
      end

      context "(when r is passed)" do
        let(:command) { "runbook exec -r ssh_kit #{runbook_file}" }

        it "runs the runbook" do
          output_lines.each do |line|
            expect(last_command_started).to have_output(line)
          end
        end
      end
    end
  end
end
