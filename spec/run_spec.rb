require "spec_helper"

RSpec.describe "Runbook::Run" do
  subject { Runbook::Run.new }
  let (:object) { Runbook::Entities::Book.new("title") }
  let (:metadata_override) { {} }
  let (:metadata) {
    {
      noop: false,
      auto: false,
      start_at: 0,
      depth: 1,
      index: 0,
      parent: nil,
      position: "",
    }.merge(metadata_override)
  }

  before(:each) do
    allow(subject).to receive(:_output)
    allow(subject).to receive(:_warn)
    allow(subject).to receive(:_error)
    allow(subject).to receive(:_exit)
  end

  describe "execute" do
    it "executes on an object" do
      expect(subject).to receive(:runbook__entities__book).with(object, metadata)

      subject.execute(object, metadata)
    end

    it "sends an error if an unknown object is executed on" do
      err_msg = /ERROR! No execution rule for Object \(object\)/
      expect(subject).to receive(:_error).with(err_msg)

      subject.execute(Object.new, metadata)
    end

    context "when position < start_at" do
      let(:metadata_override) { {start_at: "1.10", position: "1.2"} }

      it "does not execute on the object" do
        expect(
          subject
        ).to_not receive(:runbook__entities__book).with(object, metadata)

        subject.execute(object, metadata)
      end
    end

    context "when position == start_at" do
      let(:metadata_override) { {start_at: "1.10", position: "1.10"} }

      it "executes on the object" do
        expect(
          subject
        ).to receive(:runbook__entities__book).with(object, metadata)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__entities__book" do
    let (:object) { Runbook::Entities::Book.new("title") }

    it "outputs the title of the book" do
      msg = "Executing title...\n\n"
      expect(subject).to receive(:_output).with(msg)

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__section" do
    let (:object) { Runbook::Entities::Section.new("My Section") }
    let(:metadata_override) { {position: "5"} }

    it "outputs the section and position" do
      msg = "Section 5: My Section\n\n"
      expect(subject).to receive(:_output).with(msg)

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__step" do
    let (:object) { Runbook::Entities::Step.new("My Step") }
    let(:metadata_override) { {position: "1.1"} }

    it "outputs the step and position" do
      msg = "Step 1.1: My Step\n\n"
      expect(subject).to receive(:_output).with(msg)

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__ask" do
    let (:prompt) { "Sky blue?" }
    let (:into) { :sky_color }
    let (:object) { Runbook::Statements::Ask.new(prompt, into: into) }
    let(:metadata_override) do
      {
        parent: Runbook::Entities::Step.new("step")
      }
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the ask statement" do
        msg = "[NOOP] Ask: #{prompt} (store in: #{into})"
        expect(subject).to receive(:_output).with(msg)

        subject.execute(object, metadata)
      end
    end

    context "auto" do
      let(:metadata_override) { {auto: true} }

      it "raises an ExecutionError" do
        error_msg = "ERROR! Can't execute ask statement in automatic mode!"
        expect(subject).to receive(:_error).with(error_msg)

        expect do
          subject.execute(object, metadata)
        end.to raise_error(Runbook::Runner::ExecutionError, error_msg)
      end
    end

    it "prompts the user and stores the result on the parent object" do
      result = "result"
      expect(subject.prompt).to receive(:ask).with(prompt).and_return(result)

      subject.execute(object, metadata)

      expect(metadata[:parent].sky_color).to eq(result)
    end
  end

  describe "runbook__entities__confirm" do
    let (:prompt) { "Sky blue?" }
    let (:object) { Runbook::Statements::Confirm.new(prompt) }

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the confirm statement" do
        msg = "[NOOP] Prompt: #{prompt}"
        expect(subject).to receive(:_output).with(msg)
        expect(subject.prompt).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "auto" do
      let(:metadata_override) { {auto: true} }

      it "outputs auto text for the confirm statement" do
        skip_msg = "Skipping confirmation (auto): #{prompt}"
        expect(subject).to receive(:_output).with(skip_msg)
        expect(subject.prompt).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is affirmative" do
      let (:prompt_result) { true }

      it "does not exit" do
        expect(
          subject.prompt
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(subject).to_not receive(:_exit)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is not affirmative" do
      let (:prompt_result) { false }

      it "exits" do
        expect(
          subject.prompt
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(subject).to receive(:_exit).with(1)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__entities__description" do
    let (:description) { "\nMy lengthy description...\n\n" }
    let (:object) { Runbook::Statements::Description.new(description) }

    it "outputs the description" do
      expect(subject).to receive(:_output).with("#{description}\n")

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__monitor" do
    let (:prompt) { "Sky blue?" }
    let (:cmd) { "echo 'hi'" }
    let (:object) do
      Runbook::Statements::Monitor.new(cmd: cmd, prompt: prompt)
    end

    it "outputs the command with instructions" do
      msg1 = "Run the following in a separate pane:"
      msg2 = "`#{cmd}`"
      expect(subject).to receive(:_output).with(msg1).ordered
      expect(subject).to receive(:_output).with(msg2).ordered
      expect(subject.prompt).to receive(:yes?).and_return(true)

      subject.execute(object, metadata)
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the monitor statement" do
        msg = "[NOOP] Prompt: #{prompt}"
        expect(subject).to receive(:_output).with(msg)
        expect(subject.prompt).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "auto" do
      let(:metadata_override) { {auto: true} }

      it "outputs auto text for the monitor statement" do
        skip_msg = "Skipping confirmation (auto): #{prompt}"
        expect(subject).to receive(:_output).with(skip_msg)
        expect(subject.prompt).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is affirmative" do
      let (:prompt_result) { true }

      it "does not exit" do
        expect(
          subject.prompt
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(subject).to_not receive(:_exit)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is not affirmative" do
      let (:prompt_result) { false }

      it "exits" do
        expect(
          subject.prompt
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(subject).to receive(:_exit).with(1)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__entities__note" do
    let (:note) { "My note..." }
    let (:object) { Runbook::Statements::Note.new(note) }

    it "outputs the note" do
      expect(subject).to receive(:_output).with("Note: #{note}")

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__notice" do
    let (:notice) { "Warning..." }
    let (:object) { Runbook::Statements::Notice.new(notice) }

    it "outputs the notice" do
      expect(subject).to receive(:_warn).with("Notice: #{notice}")

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__wait" do
    let (:time) { 60 }
    let (:object) { Runbook::Statements::Wait.new(time) }

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the wait statement" do
        msg = "[NOOP] Sleep #{time} seconds"
        expect(subject).to receive(:_output).with(msg)
        expect(subject).to_not receive(:sleep)

        subject.execute(object, metadata)
      end
    end

    it "calls 'sleep' _time_ times" do
      expect(TTY::ProgressBar).to receive(:new).and_return(
        spy("TTY::ProgressBar")
      )
      expect(subject).to receive(:sleep).exactly(time).times

      subject.execute(object, metadata)
    end
  end
end
