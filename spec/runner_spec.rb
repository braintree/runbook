require "spec_helper"

RSpec.describe Runbook::Runner do
  let(:book_title) { "My Book" }
  let(:book) do
    Runbook.book book_title do
      description <<-DESC
This is a very elaborate runbook that does stuff
      DESC

      section "Parent Section" do
        section "First Section" do
          step "Step 1" do
            note "I like cheese"
            note "I also like carrots"
          end
        end

        section "Second Section" do
          step "Step 1" do
            notice "Some cheese is actually yellow plastic"
            ruby_command do |rb_cmd, metadata|
              metadata[:toolbox].output("I like cheese whiz!")
            end
          end
        end
      end
    end
  end
  let(:runner) { Runbook::Runner.new(book) }

  it "defaults to run using ssh_kit" do
    expect(book).to receive(:run).with(Runbook::Runs::SSHKit, Hash)
    runner.run
  end

  it "defaults to run in paranoid mode" do
    expect(book).to receive(:run).with(
      Runbook::Runs::SSHKit,
      hash_including(paranoid: true),
    )
    runner.run
  end

  context "with ssh_kit run" do
    let(:run) { :ssh_kit }
    let(:output) { StringIO.new }

    before(:each) do
      allow_any_instance_of(Runbook::Toolbox).to receive(:output) do |instance, msg|
        output.puts(msg)
      end
      allow_any_instance_of(Runbook::Toolbox).to receive(:warn) do |instance, msg|
        output.puts(msg)
      end
    end

    it "runs the book using the ssk_kit run" do
      runner.run(run: run, paranoid: false)

      expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Description:
This is a very elaborate runbook that does stuff

Section 1: Parent Section

Section 1.1: First Section

Step 1.1.1: Step 1

Note: I like cheese
Note: I also like carrots

Section 1.2: Second Section

Step 1.2.1: Step 1

Notice: Some cheese is actually yellow plastic
I like cheese whiz!

OUTPUT
    end

    context "with noop: true" do
      it "outputs noop messages" do
        runner.run(run: run, noop: true)

        expect(output.string).to eq(<<-NOOP)
Executing My Book...

Description:
This is a very elaborate runbook that does stuff

Section 1: Parent Section

Section 1.1: First Section

Step 1.1.1: Step 1

Note: I like cheese
Note: I also like carrots

Section 1.2: Second Section

Step 1.2.1: Step 1

Notice: Some cheese is actually yellow plastic
[NOOP] Run the following Ruby block:
```ruby
ruby_command do |rb_cmd, metadata|
  metadata[:toolbox].output("I like cheese whiz!")
end
```

NOOP
      end
    end

    context "with auto: true" do
      let(:book) do
        Runbook.book "My Book" do
          description <<-DESC
This is a very elaborate runbook that does stuff
          DESC

          section "Parent Section" do
            section "First Section" do
              step "Cheese inspection" do
                note "I like cheese"
                confirm "You really like cheese?"
                note "I also like carrots"
              end
            end
          end
        end
      end

      it "does not prompt for confirmation" do
        runner.run(run: run, auto: true)

        expect(output.string).to eq(<<-NOOP)
Executing My Book...

Description:
This is a very elaborate runbook that does stuff

Section 1: Parent Section

Section 1.1: First Section

Step 1.1.1: Cheese inspection

Note: I like cheese
Skipping confirmation (auto): You really like cheese?
Note: I also like carrots

NOOP
      end
    end

    context "with paranoid: true" do
      let(:book) do
        Runbook.book "My Book" do
          section "Parent Section" do
            step "Cheese inspection"
            step "?"
            step "Profit"
          end
        end
      end

      it "prompts to continue" do
        expect_any_instance_of(Runbook::Toolbox).to receive(:expand).with("Continue?", Array).thrice

        runner.run(run: run, paranoid: true)

        expect(output.string).to eq(<<-NOOP)
Executing My Book...

Section 1: Parent Section

Step 1.1: Cheese inspection

Step 1.2: ?

Step 1.3: Profit

NOOP
      end

      context "when prompt is told to disable paranoid mode" do
        it "no longer prompts" do
          expect_any_instance_of(Runbook::Toolbox).to receive(:expand).with("Continue?", Array).once.and_return(:no_paranoid)

          runner.run(run: run, paranoid: true)

          expect(output.string).to eq(<<-PARANOID)
Executing My Book...

Section 1: Parent Section

Step 1.1: Cheese inspection

Step 1.2: ?

Step 1.3: Profit

          PARANOID
        end
      end
    end

    context "with start_at == 0" do
      context "when there is a stored position" do
        let(:current_pose) { "1.2" }

        before(:each) do
          Runbook::Util::StoredPose.save(current_pose, book_title: book_title)
        end

        it "prompts to resume at the stored position" do
          expect_any_instance_of(
            Runbook::Toolbox
          ).to receive(:yes?).and_return(true)
          runner.run(run: run, paranoid: false)
          pose_output = "Previous position detected: #{current_pose}"
          expect(output.string).to include(pose_output)
        end

        context "when running in auto mode" do
          it "does not update :start_at" do
            expect_any_instance_of(Runbook::Toolbox).to_not receive(:yes?)
            runner.run(run: run, paranoid: false, auto: true)
            expect(output.string).to include("Section 1:")
          end
        end

        context "when running in noop mode" do
          it "does not update :start_at" do
            expect_any_instance_of(Runbook::Toolbox).to_not receive(:yes?)
            runner.run(run: run, paranoid: false, noop: true)
            expect(output.string).to include("Section 1:")
          end
        end

        context "when starting at the stored position" do
          before(:each) do
            expect_any_instance_of(
              Runbook::Toolbox
            ).to receive(:yes?).and_return(true)
          end

          it "updates :start_at" do
            runner.run(run: run, paranoid: false)
            expect(output.string).to_not include("Section 1:")
          end
        end

        context "when not starting at the stored position" do
          before(:each) do
            expect_any_instance_of(
              Runbook::Toolbox
            ).to receive(:yes?).and_return(false)
          end

          it "does not update :start_at" do
            runner.run(run: run, paranoid: false)
            expect(output.string).to include("Section 1:")
          end
        end
      end
    end

    context "with start_at > 0" do
      it "skips parts less than start_at" do
        runner.run(run: run, paranoid: false, start_at: "1.2.1")

        expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Description:
This is a very elaborate runbook that does stuff

Step 1.2.1: Step 1

Notice: Some cheese is actually yellow plastic
I like cheese whiz!

OUTPUT
      end
    end

    context "passing data between steps" do
      let(:book) do
        Runbook.book "My Book" do
          section "Parent Section" do
            step "Cheese inspection" do
              ruby_command do |rb_cmd, metadata|
                metadata[:repo][:result] = "Good cheese!"
              end
            end
            step "?"
            step "Profit" do
              ruby_command do |rb_cmd, metadata|
                metadata[:toolbox].output(metadata[:repo][:result])
              end
            end
          end
        end
      end

      it "allows data to be passed using the repo metadata" do
        runner.run(run: run, paranoid: false)

        expect(output.string).to eq(<<-PARANOID)
Executing My Book...

Section 1: Parent Section

Step 1.1: Cheese inspection


Step 1.2: ?

Step 1.3: Profit

Good cheese!

        PARANOID
      end

      context "when starting in the middle of a runbook" do
        it "attempts to load an existing repo" do
          expect(Runbook::Util::Repo).to receive(:load).and_call_original
          runner.run(run: run, paranoid: false, start_at: "1")
        end
      end

      context "when start_at is nil" do
        it "does not attempt to load an existing repo" do
          expect(Runbook::Util::Repo).to_not receive(:load)
          runner.run(run: run, paranoid: false, start_at: nil)
        end
      end
    end

    context "invoking commands within ruby_command" do
      let(:book) do
        Runbook.book "My Book" do
          section "Section" do
            step do
              ruby_command do |rb_cmd, metadata|
                metadata[:repo][:cmd] = "note invoked!"
              end

              ruby_command do |rb_cmd, metadata|
                note metadata[:repo][:cmd]
              end

              note "Run me last"
            end
          end
        end
      end

      it "runs the commands as children of the step" do
        runner.run(run: run, paranoid: false)

        expect(output.string).to eq(<<-PARANOID)
Executing My Book...

Section 1: Section

Step 1.1:

Note: note invoked!
Note: Run me last

        PARANOID
      end
    end
  end

  context "layout" do
    let(:run) { :ssh_kit }
    let(:title) { "My Book" }
    let(:output) { StringIO.new }

    before(:each) do
      allow_any_instance_of(
        Runbook::Toolbox
      ).to receive(:output) do |instance, msg|
        output.puts(msg)
      end
    end

    context "without layout_panes" do
      let(:book) do
        Runbook.book(title) { }
      end

      it "does not kill all panes" do
        expect(
          Runbook::Runs::SSHKit
        ).to_not receive(:kill_all_panes)

        runner.run(run: run, paranoid: false)
      end
    end

    context "with layout_panes" do
      let(:my_layout) { [:runbook, :deploy] }
      let(:layout_panes) {
        {:runbook => "%1", :deploy => "%3"}
      }
      let(:book) do
        Runbook.book title do
          layout [:runbook, :deploy]
        end
      end

      context "with noop: true" do
        it "does not kill all panes" do
          expect(
            Runbook::Runs::SSHKit
          ).to_not receive(:kill_all_panes)

          runner.run(
            run: run,
            auto: true,
            noop: true,
            paranoid: false
          )
        end
      end

      context "with noop: false" do
        before(:each) do
          expect(
            Runbook::Runs::SSHKit
          ).to receive(:setup_layout).
          with(my_layout, runbook_title: title).
          and_return(layout_panes)
        end

        context "with auto: true" do
          it "kills all panes without prompting" do
            expect_any_instance_of(
              Runbook::Toolbox
            ).to_not receive(:yes?)

            expect(
              Runbook::Runs::SSHKit
            ).to receive(:kill_all_panes).with(layout_panes)

            runner.run(
              run: run,
              auto: true,
              noop: false,
              paranoid: false
            )

            expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Killing all opened tmux panes...
  OUTPUT
          end
        end

        context "with auto: false" do
          context "when prompt returns true" do
            before(:each) do
              expect_any_instance_of(
                Runbook::Toolbox
              ).to receive(:yes?).and_return(true)
            end

            it "kills all panes" do
              expect(
                Runbook::Runs::SSHKit
              ).to receive(:kill_all_panes)

              runner.run(
                run: run,
                auto: false,
                noop: false,
                paranoid: false
              )
            end
          end

          context "when prompt returns false" do
            before(:each) do
              expect_any_instance_of(
                Runbook::Toolbox
              ).to receive(:yes?).and_return(false)
            end

            it "does not kill all panes" do
              expect(
                Runbook::Runs::SSHKit
              ).to_not receive(:kill_all_panes)

              runner.run(
                run: run,
                auto: false,
                noop: false,
                paranoid: false
              )
            end
          end
        end
      end
    end
  end

  context "shared variables" do
    let(:run) { :ssh_kit }
    let(:output) { StringIO.new }
    let(:book) do
      Runbook.book "My Book" do
        section "My Section" do
          step do
            ruby_command do |rb_cmd, metadata|
              val = "a shared val"
              note "Setting my_shared to #{val}"
              @my_shared = val
            end
          end

          step do
            ruby_command do |rb_cmd, metadata|
              note @my_shared
            end
          end
        end
      end
    end

    before(:each) do
      allow_any_instance_of(Runbook::Toolbox).to receive(:output) do |instance, msg|
        output.puts(msg)
      end
    end

    it "exposes ivars between ruby_command blocks" do
      runner.run(run: run, paranoid: false)

      expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:

Note: Setting my_shared to a shared val

Step 1.2:

Note: a shared val

OUTPUT
    end

    context "with ivars set in entities" do
      let(:book) do
        Runbook.book "My Book" do
          @shared2 = "party time"

          section "My Section" do
            @shared1 = "excellent"
            step do
              @shared3 = "old value"
            end

            step do
              ruby_command do |rb_cmd, metadata|
                note "value:#{@shared2}"
              end
            end
          end

          section "Section 2" do
            step do
              ruby_command { note "1.#{@shared1}" }
              ruby_command { note "2.#{@shared2}" }
              ruby_command { note "3.#{@shared3}" }
              ruby_command { note "4.#{@shared4}" }
            end
          end

          @shared4 = "late to the party"
        end
      end

      it "Does not expose the ivars in the ruby_command context" do
      runner.run(run: run, paranoid: false)

      expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:

Step 1.2:

Note: value:

Section 2: Section 2

Step 2.1:

Note: 1.
Note: 2.
Note: 3.
Note: 4.

OUTPUT
      end
    end

    context "with locals set in entities" do
      let(:book) do
        shared1 = "Show time"

        Runbook.book "My Book" do
          shared2 = "Wayne's World"

          section "My Section" do
            shared3 = "party time"

            step do
              shared4 = "excellent"

              ruby_command do |rb_cmd, metadata|
                note shared1
                note shared2
                note shared3
                note shared4
              end
            end
          end
        end
      end

      it "Exposes the locals in the ruby_command context" do
      runner.run(run: run, paranoid: false)

      expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:

Note: Show time
Note: Wayne's World
Note: party time
Note: excellent

OUTPUT
      end
    end

    context "with ivars set via repo" do
      let(:book) do
        Runbook.book "My Book" do
          section "My Section" do
            @a_shared_var = "excellent"

            step do
              ruby_command do |rb_cmd, metadata|
                metadata[:repo][:shared1] = "Sweet!"
              end

              ruby_command { note @shared1 }
            end
          end
        end
      end

      it "exposes the ivar in the ruby_command context" do
        runner.run(run: run, paranoid: false)

        expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:

Note: Sweet!

OUTPUT
      end
    end

    context "with ivars set via instance_variable" do
      let(:book) do
        Runbook.book "My Book" do
          section "My Section" do
            step do
              ruby_command do
                @shared1 = "Sweet!"
              end

              ruby_command do |_, metadata|
                note metadata[:repo][:shared1]
              end
            end
          end
        end
      end

      it "exposes the ivar in the repo" do
      runner.run(run: run, paranoid: false)

      expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:

Note: Sweet!

OUTPUT
      end
    end

    context "with ivars set via setter method" do
      let(:book) do
        Runbook.book "My Book" do
          section "S1" do
            step do
              ruby_command { @shared1 = nil }
            end
          end

          section "My Section" do
            step do
              ruby_command do
                self.shared1 = "Gnarly!"
              end

              ruby_command do |_, metadata|
                note shared1
              end
            end
          end
        end
      end

      it "exposes the ivar via attr_reader" do
        runner.run(run: run, paranoid: false)

        expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: S1

Step 1.1:


Section 2: My Section

Step 2.1:

Note: Gnarly!

OUTPUT
      end
    end

    context "with shared variables set via repo" do
      let(:book) do
        Runbook.book "My Book" do
          section "My Section" do
            step do
              ruby_command do |_, metadata|
                metadata[:repo][:shared1] = "Bodacious!"
              end

              ruby_command do |_, metadata|
                note shared1
              end
            end
          end
        end
      end

      it "exposes the shared_var via attr_reader" do
      runner.run(run: run, paranoid: false)

      expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:

Note: Bodacious!

OUTPUT
      end
    end

    context "with auto: false" do
      before(:each) do
        expect_any_instance_of(
          Runbook::Toolbox
        ).to receive(:ask).and_return("Blue!")
      end

      let(:book) do
        Runbook.book "My Book" do
          section "My Section" do
            step do
              ask "Favorite Color?", into: :color
            end
          end

          section "Section 2" do
            step do
              ruby_command do |_, metadata|
                note color
              end
            end
          end
        end
      end

      it "stores the result of ask in an ivar" do
        runner.run(run: run, paranoid: false)

        expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:


Section 2: Section 2

Step 2.1:

Note: Blue!

OUTPUT
      end
    end

    context "with auto: true" do
      let(:book) do
        Runbook.book "My Book" do
          section "My Section" do
            step do
              ask "Favorite Color?", into: :color, default: "Yellow!"
            end
          end

          section "Section 2" do
            step do
              ruby_command do |_, metadata|
                note color
              end
            end
          end
        end
      end

      it "stores the default value of ask in an ivar" do
        runner.run(run: run, auto: true, paranoid: false)

        expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:


Section 2: Section 2

Step 2.1:

Note: Yellow!

OUTPUT
      end
    end

    context "capture command" do
      let(:result) { "hi!" }
      let(:book) do
        Runbook.book "My Book" do
          section "My Section" do
            step do
              capture "echo 'hi!'", into: :capture_result
            end
          end

          section "Section 2" do
            step do
              ruby_command do |_, metadata|
                note metadata[:repo][:capture_result]
              end
            end
          end
        end
      end

      it "captures cmd" do
        capture_args = [:echo, "'hi!'", {:strip => true}]
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:capture).with(*capture_args).and_return(result)

        runner.run(run: run, paranoid: false)

        expect(output.string).to eq(<<-OUTPUT)
Executing My Book...

Section 1: My Section

Step 1.1:



Section 2: Section 2

Step 2.1:

Note: hi!

OUTPUT
      end
    end
  end
end
