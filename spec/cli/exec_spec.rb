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
  let(:book_title) { "My Runbook" }
  let(:content) do
    <<-RUNBOOK
    runbook = Runbook.book "#{book_title}" do
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
  let(:repo_file) {
    Runbook::Util::Repo._file(book_title)
  }
  let(:stored_pose_file) {
    Runbook::Util::StoredPose._file(book_title)
  }

  before(:each) { write_file(config_file, config_content) }
  before(:each) { write_file(runbook_file, content) }
  before(:each) do
    FileUtils.rm_f(repo_file)
    FileUtils.rm_f(stored_pose_file)
  end

  before(:each) { run_command(command) }

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
          expect(last_command_started).to have_output(/My Runbook/)
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

    context "When resuming a stopped runbook" do
      let(:content) do
        <<-RUNBOOK
        runbook = Runbook.book "#{book_title}" do
          section "First Section" do
            step "Ask stuff" do
              ask "What's the meaning of life?", into: :life_meaning, default: "42"
            end

            step do
              ruby_command { note life_meaning }
            end
          end
        end
        #{runbook_registration}
        RUNBOOK
      end

      let(:command) { "runbook exec #{runbook_file}" }
      let(:second_command) { "runbook exec -s 1.1 #{runbook_file}" }

      it "sets previous values as ask defaults" do
        type("c\ncandy\ne")

        expect(repo_file).to be_an_existing_file

        run_command(second_command)

        type("c\n\nP")

        expect(
          last_command_started
        ).to have_output(/candy/)
      end
    end

    context "when paranoid is passed" do
      let(:command) { "runbook exec #{runbook_file}" }
      let(:book_title) { "My Runbook" }
      let(:content) do
        <<-RUNBOOK
        Runbook::Runs::SSHKit.register_hook(
          :after_desc_hook,
          :after,
          Runbook::Statements::Description
        ) do |object, metadata|
          metadata[:toolbox].output(" After description hook\n")
        end

        Runbook::Runs::SSHKit.register_hook(
          :after_step_hook,
          :after,
          Runbook::Entities::Step
        ) do |object, metadata|
          metadata[:toolbox].output(" After Step \#{metadata[:position]}\n")
        end

        runbook = Runbook.book "#{book_title}" do
          description "My description\n"

          section "First Section" do
            step "Ask for continue" do
              note "hi"
            end

            step "Another step" do
              note "step here"
            end
          end

          section "Second Section" do
            step "skip me" do
              note "never run"
            end

            step "Jump here" do
              note "you jumped"
            end
          end
        end

        Runbook.books[:my_runbook] = runbook
        RUNBOOK
      end
      let(:total_output) {
        title_output +
        description_output +
        after_description_output +
        section_1_output +
        section_2_output
      }
      let(:title_output) {
        [/Executing My Runbook\.\.\./]
      }
      let(:description_output) {
        [/My description/]
      }
      let(:after_description_output) {
        [/After description hook/]
      }
      let(:section_1_output) {
        [
          /Section 1: First Section/,
        ] +
        step_1_1_title +
        step_1_1_output +
        step_1_2_title +
        step_1_2_output
      }
      let(:step_1_1_title) {
        [/Step 1\.1: Ask for continue/]
      }
      let(:step_1_1_output) {
        [/Note: hi/]
      }
      let(:step_1_2_title) {
        [/Step 1\.2: Another step/]
      }
      let(:step_1_2_output) {
        [/Note: step here/]
      }
      let(:section_2_output) {
        section_2_title +
        step_2_1_title +
        step_2_1_output +
        step_2_2_title +
        step_2_2_output
      }
      let(:section_2_title) {
        [/Section 2: Second Section/]
      }
      let(:step_2_1_title) {
        [/Step 2\.1: skip me/]
      }
      let(:step_2_1_output) {
        [/Note: never run/]
      }
      let(:step_2_2_title) {
        [/Step 2\.2: Jump here/]
      }
      let(:step_2_2_output) {
        [/Note: you jumped/]
      }

      it "prompts to continue" do
        type("c\nc\nc\nc")

        total_output.each do |line|
          expect(last_command_started).to have_output(line)
        end
        expect(last_command_started).to have_output(/Continue\?/)
      end

      context "when skip is passed" do
        it "skips the step" do
          type("s\nc\nc\nc")

          (total_output - step_1_1_output).each do |line|
            expect(last_command_started).to have_output(line)
          end
          step_1_1_output.each do |line|
            expect(last_command_started).to_not have_output(line)
          end
        end
      end

      context "when jump is passed" do
        it "jumps to the step" do
          type("j\n2.2\nc\nc")

          excludes = step_1_1_output +
            step_1_2_title +
            step_1_2_output +
            section_2_title +
            step_2_1_title +
            step_2_1_output
          (total_output - excludes).each do |line|
            expect(last_command_started).to have_output(line)
          end
          (excludes).each do |line|
            expect(last_command_started).to_not have_output(line)
          end
        end

        context "when jumping to the same step" do
          it "replays the step" do
            type("j\n1.1\nP")

            regex = /#{step_1_1_title[0]}.*#{step_1_1_title[0]}/m
            expect(last_command_started).to have_output(regex)
          end
        end

        context "when jumping to a past step" do
          it "resumes at that step" do
            type("j\n2.1\nj\n1.2\nP")

            regex = /step here/
            expect(last_command_started).to have_output(regex)
            step_2_2_regex = /#{step_2_2_title[0]}.*#{step_2_2_title[0]}/m
            expect(last_command_started).to_not have_output(step_2_2_regex)
          end

          it "runs after hooks for the current step" do
            type("j\n2.2\nj\n1.2\nP")

            regex = / After Step 2\.2.* After Step 2\.2/m
            expect(last_command_started).to have_output(regex)
          end

          it "does not re-execute the book's description" do
            type("j\n2.2\nj\n1.2\nP")

            regex = /#{description_output[0]}.*#{description_output[0]}/m
            expect(last_command_started).to_not have_output(regex)
          end

          it "does not re-execute the book's description after hook" do
            type("j\n2.2\nj\n1.2\nP")

            regex = /#{after_description_output[0]}.*#{after_description_output[0]}/m
            expect(last_command_started).to_not have_output(regex)
          end
        end

        context "when jumping to the beginning of the book" do
          it "re-execute's the book's description" do
            type("j\n2.2\nj\n0\nP")

            regex = /#{description_output[0]}.*#{description_output[0]}/m
            expect(last_command_started).to have_output(regex)
          end
        end

        context "when jumping to a non-existent step" do
          it "resumes at the immediately following step" do
            type("j\n2.2\nj\n1.5\nP")

            step_1_2_regex = /#{step_1_2_output[0]}.*#{step_1_2_output[0]}/m
            expect(last_command_started).to_not have_output(step_1_2_regex)
            section_2_output.each do |line|
              expect(last_command_started).to have_output(line)
            end
          end
        end
      end

      context "when no paranoid is passed" do
        it "stops prompting to continue" do
          type("P\ns")

          total_output.each do |line|
            expect(last_command_started).to have_output(line)
          end
        end
      end

      context "when exit is passed" do
        it "exits the run" do
          type("e")

          (step_1_1_output + step_1_2_title + section_2_output).each do |line|
            expect(last_command_started).to_not have_output(line)
          end
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
      let(:stored_pose_file) {
        Runbook::Util::StoredPose._file(book_title)
      }
      let(:message) { "Hello!" }
      let(:content) do
        <<-RUNBOOK
        Runbook.book "#{book_title}" do
          section "First Section" do
            step { note "I get skipped" }
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
        FileUtils.rm_f(stored_pose_file)
      end

      it "persists state across runbook invocations" do
        expect(repo_file).to be_an_existing_file
        expect(stored_pose_file).to be_an_existing_file

        run_command(second_command)

        expect(
          last_command_started
        ).to have_output(/Message2: #{message}/)
        expect(repo_file).to_not be_an_existing_file
        expect(stored_pose_file).to_not be_an_existing_file
      end

      context "when start_at is not passed in second invocation" do
        let(:second_command) { "runbook exec -P #{runbook_file}" }

        it "prompts to resume stopped runbook invocations" do
          # This spec becomes flaky without this assertion
          expect(stored_pose_file).to be_an_existing_file

          run_command(second_command)

          # Yes to resume from previous pose prompt
          type("y")

          expect(
            last_command_started
          ).to_not have_output(/I get skipped/)
        end
      end

      context "when start_at is passed in second invocation" do
        let(:second_command) { "runbook exec -P -s 1 #{runbook_file}" }

        it "does not prompt to resume stopped runbook invocations" do
          expect(stored_pose_file).to be_an_existing_file

          run_command(second_command)

          expect(
            last_command_started
          ).to have_output(/I get skipped/)
        end
      end

      context "when rerunning from scratch" do
        it "does not load persisted state" do
          run_command(command)

          # No to resume from previous pose prompt
          type("n")

          expect(
            last_command_started
          ).to have_output(/Message1:/)
          expect(
            last_command_started
          ).to_not have_output(/Message1: #{message}/)
        end
      end
    end
  end
end
