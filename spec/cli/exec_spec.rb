require "spec_helper"

RSpec.describe "runbook run", type: :aruba do
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

  before(:each) { write_file(config_file, config_content) }
  before(:each) { write_file(runbook_file, content) }
  before(:each) { run(command) }

  describe "input specification" do
    context "runbook is passed as an argument" do
      let(:command) { "runbook exec -P #{runbook_file}" }
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

    context "when no-paranoid is passed" do
      let(:command) { "runbook exec --no-paranoid #{runbook_file}" }
      let(:content) do
        <<-RUNBOOK
        Runbook.book "My Runbook" do
          section "First Section" do
            step "Do not ask for continue"
          end
        end
        RUNBOOK
      end
      let(:output_lines) {
        [
          /Executing My Runbook\.\.\./,
          /Section 1: First Section/,
          /Step 1\.1: Do not ask for continue/,
        ]
      }

      it "does not prompt" do
        output_lines.each do |line|
          expect(last_command_started).to have_output(line)
        end
        expect(last_command_started).to_not have_output(/Continue\?/)
      end

      context "(when P is passed)" do
        let(:command) { "runbook exec -P #{runbook_file}" }

        it "does not prompt" do
          output_lines.each do |line|
            expect(last_command_started).to have_output(line)
          end
          expect(last_command_started).to_not have_output(/Continue\?/)
        end
      end
    end

    context "when start_at is passed" do
      let(:command) { "runbook exec -P --start-at 1.2 #{runbook_file}" }
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
        let(:command) { "runbook exec -P -s 1.2 #{runbook_file}" }

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
      let(:command) { "runbook exec -P --run ssh_kit #{runbook_file}" }
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
        let(:command) { "runbook exec -P -r ssh_kit #{runbook_file}" }

        it "runs the runbook" do
          output_lines.each do |line|
            expect(last_command_started).to have_output(line)
          end
        end
      end
    end

    context "when config is passed" do
      let(:command) { "runbook exec -P --config #{config_file} #{runbook_file}" }

      it "executes the runbook using the specified configuration" do
        expect(last_command_started).to have_output(/\n\./)
      end

      context "(when c is passed)" do
        let(:command) { "runbook exec -P -c #{config_file} #{runbook_file}" }

        it "executes the runbook using the specified configuration" do
          expect(last_command_started).to have_output(/\n\./)
        end
      end

      context "when config does not exist" do
        let(:command) { "runbook exec -P --config unknown #{runbook_file}" }
        let(:unknown_file_output) {
          "exec: cannot access unknown: No such file or directory"
        }

        it "prints an unknown file message" do
          expect(
            last_command_started
          ).to have_output(unknown_file_output)
        end
      end
    end

    context "persisted state" do
      let(:book_title) { "My Persisted Runbook" }
      let(:repo_file) {
        Runbook::Util::Repo._file(book_title)
      }
      let(:message) { "Hello!" }
      let(:content) do
        <<-RUNBOOK
        Runbook.book "#{book_title}" do
          section "First Section" do
            step do
              ruby_command do |rb_cmd, metadata|
                message = metadata[:repo][:message]
                metadata[:toolbox].output("Message1: \#{message}")
              end
              ruby_command do |rb_cmd, metadata|
                metadata[:repo][:message] = "#{message}"
              end
              ruby_command { exit }
            end
          end

          section "Second Section" do
            step do
              ruby_command do |rb_cmd, metadata|
                message = metadata[:repo][:message]
                metadata[:toolbox].output("Message2: \#{message}")
              end
            end
          end
        end
        RUNBOOK
      end
      let(:command) { "runbook exec -P #{runbook_file}" }
      let(:second_command) { "runbook exec -P -s 2 #{runbook_file}" }

      after(:each) do
        FileUtils.rm_f(repo_file)
      end

      it "persists state across runbook invocations" do
        expect(repo_file).to be_an_existing_file

        run(second_command)

        expect(
          last_command_started
        ).to have_output(/Message2: #{message}/)
        expect(repo_file).to_not be_an_existing_file
      end

      context "when rerunning from scratch" do
        it "does not load persisted state" do
          run(command)

          expect(
            last_command_started
          ).to_not have_output(/Message1: #{message}/)
        end
      end
    end
  end
end
