require "spec_helper"

RSpec.describe Runbook::Runner do
  let(:book) do
    Runbook.book "My Book" do
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
end
