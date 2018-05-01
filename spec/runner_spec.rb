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
            ruby_command do
              _output("I like cheese whiz!")
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

  context "with ssh_kit run" do
    let(:run) { :ssh_kit }
    let(:output) { StringIO.new }

    before(:each) do
      allow_any_instance_of(Runbook::Runs::SSHKit).to receive(:_output) do |instance, msg|
        output.puts(msg)
      end
      allow_any_instance_of(Runbook::Runs::SSHKit).to receive(:_warn) do |instance, msg|
        output.puts(msg)
      end
    end

    it "runs the book using the ssk_kit run" do
      runner.run(run: run)

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
ruby_command do
  _output("I like cheese whiz!")
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
                monitor(
                  cmd: "tail -fn 100 /var/log/food_journal.log",
                  prompt: "Did you eat cheese yesterday?",
                )
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
Run the following in a separate pane:
`tail -fn 100 /var/log/food_journal.log`
Skipping confirmation (auto): Did you eat cheese yesterday?

NOOP
      end
    end

    context "with start_at > 0" do
      it "skips parts less than start_at" do
        runner.run(run: run, start_at: "1.2.1")

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
  end
end
