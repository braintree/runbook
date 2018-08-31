require "spec_helper"

RSpec.describe "Runbook::Run" do
  subject { Class.new { include Runbook::Run } }
  let (:object) { Runbook::Entities::Book.new("title") }
  let (:metadata_override) { {} }
  let (:toolbox) { instance_double("Runbook::Toolbox") }
  let (:metadata) {
    {
      noop: false,
      auto: false,
      paranoid: true,
      start_at: "0",
      toolbox: toolbox,
      layout_panes: {},
      depth: 1,
      index: 0,
      parent: nil,
      position: "",
    }.merge(metadata_override)
  }

  describe "execute" do
    it "executes on an object" do
      expect(subject).to receive(:runbook__entities__book).with(object, metadata)

      subject.execute(object, metadata)
    end

    it "sends an error if an unknown object is executed on" do
      err_msg = /ERROR! No execution rule for Object \(object\)/
      expect(toolbox).to receive(:error).with(err_msg)

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
      expect(toolbox).to receive(:output).with(msg)

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__section" do
    let (:object) { Runbook::Entities::Section.new("My Section") }
    let(:metadata_override) { {position: "5"} }

    it "outputs the section and position" do
      msg = "Section 5: My Section\n\n"
      expect(toolbox).to receive(:output).with(msg)

      subject.execute(object, metadata)
    end
  end

  describe "runbook__entities__step" do
    let (:object) { Runbook::Entities::Step.new("My Step") }
    let(:metadata_override) { {position: "1.1"} }

    before(:each) do
      allow(toolbox).to receive(:expand).and_return(:continue)
    end

    it "outputs the step and position" do
      msg = "Step 1.1: My Step\n\n"
      expect(toolbox).to receive(:output).with(msg)

      subject.execute(object, metadata)
    end

    context "when paranoid mode is true" do
      let(:metadata_override) { {position: "1.1", paranoid: true} }

      before(:each) do
        allow(toolbox).to receive(:output)
      end

      context "when :continue" do
        it "goes to the next step" do
          expect(toolbox).to receive(:expand).and_return(:continue)
          start_at = metadata[:start_at]
          subject.execute(object, metadata)
          expect(metadata[:start_at]).to eq(start_at)
        end
      end

      context "when :skip" do
        it "skips the step" do
          expect(toolbox).to receive(:expand).and_return(:skip)
          subject.execute(object, metadata)
          expect(metadata[:start_at]).to eq("1.2")
        end
      end

      context "when :jump" do
        let (:ask_msg) { "What position would you like to jump to?" }

        it "jumps to the specified step" do
          expect(toolbox).to receive(:expand).and_return(:jump)
          expect(toolbox).to receive(:ask).with(ask_msg).and_return("1.13")
          subject.execute(object, metadata)
          expect(metadata[:start_at]).to eq("1.13")
        end
      end

      context "when :no_paranoid" do
        it "no longer prompts" do
          expect(toolbox).to receive(:expand).and_return(:no_paranoid)
          subject.execute(object, metadata)
          expect(metadata[:paranoid]).to eq(false)
        end
      end

      context "when :exit" do
        it "exits the process" do
          expect(toolbox).to receive(:expand).and_return(:exit)
          expect(toolbox).to receive(:exit).with(0)
          subject.execute(object, metadata)
        end
      end

      context "when in noop mode" do
        let(:metadata_override) { {noop: true} }

        it "does not prompt" do
          expect(toolbox).to_not receive(:expand)
          subject.execute(object, metadata)
        end
      end

      context "when in auto mode" do
        let(:metadata_override) { {auto: true} }

        it "does not prompt" do
          expect(toolbox).to_not receive(:expand)
          subject.execute(object, metadata)
        end
      end

      context "when paranoid mode is disabled" do
        let(:metadata_override) { {paranoid: false} }

        it "does not prompt" do
          expect(toolbox).to_not receive(:expand)
          subject.execute(object, metadata)
        end
      end
    end
  end

  describe "runbook__statements__ask" do
    let (:prompt) { "Sky blue?" }
    let (:into) { :sky_color }
    let (:object) { Runbook::Statements::Ask.new(prompt, into: into) }

    before(:each) do
      object.parent = Runbook::Entities::Step.new("step")
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the ask statement" do
        msg = "[NOOP] Ask: #{prompt} (store in: #{into})"
        expect(toolbox).to receive(:output).with(msg)

        subject.execute(object, metadata)
      end

      context "when default specified" do
        let (:default) { "Pope where a hat?" }
        let (:object) {
          Runbook::Statements::Ask.new(prompt, into: into, default: default)
        }

        it "outputs the default text for the ask statement" do
          msg = "[NOOP] Ask: #{prompt} (store in: #{into}) (default: #{default})"
          expect(toolbox).to receive(:output).with(msg)

          subject.execute(object, metadata)
        end
      end
    end

    context "auto" do
      let(:metadata_override) { {auto: true} }

      it "raises an ExecutionError" do
        error_msg = "ERROR! Can't execute ask statement in automatic mode!"
        expect(toolbox).to receive(:error).with(error_msg)

        expect do
          subject.execute(object, metadata)
        end.to raise_error(Runbook::Runner::ExecutionError, error_msg)
      end

      context "when default specified" do
        let (:default) { "Pope where a hat?" }
        let (:object) {
          Runbook::Statements::Ask.new(prompt, into: into, default: default)
        }

        it "sets the default value for the ask statement" do
          expect(toolbox).to_not receive(:ask)

          subject.execute(object, metadata)

          expect(object.parent.sky_color).to eq(default)
        end
      end
    end

    it "prompts the user and stores the result on the parent object" do
      result = "result"
      expect(toolbox).to receive(:ask).with(prompt, default: nil).and_return(result)

      subject.execute(object, metadata)

      expect(object.parent.sky_color).to eq(result)
    end

    context "when default specified" do
      let (:default) { "Pope where a hat?" }
      let (:object) {
        Runbook::Statements::Ask.new(prompt, into: into, default: default)
      }

      it "passes the default value to the ask statement" do
        result = "result"
        expect(toolbox).to receive(:ask).with(prompt, default: default).and_return(result)

        subject.execute(object, metadata)

        expect(object.parent.sky_color).to eq(result)
      end
    end
  end

  describe "runbook__statements__confirm" do
    let (:prompt) { "Sky blue?" }
    let (:object) { Runbook::Statements::Confirm.new(prompt) }

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the confirm statement" do
        msg = "[NOOP] Prompt: #{prompt}"
        expect(toolbox).to receive(:output).with(msg)
        expect(toolbox).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "auto" do
      let(:metadata_override) { {auto: true} }

      it "outputs auto text for the confirm statement" do
        skip_msg = "Skipping confirmation (auto): #{prompt}"
        expect(toolbox).to receive(:output).with(skip_msg)
        expect(toolbox).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is affirmative" do
      let (:prompt_result) { true }

      it "does not exit" do
        expect(
          toolbox
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(toolbox).to_not receive(:exit)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is not affirmative" do
      let (:prompt_result) { false }

      it "exits" do
        expect(
          toolbox
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(toolbox).to receive(:exit).with(1)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__statements__description" do
    let (:description) { "\nMy lengthy description...\n\n" }
    let (:object) { Runbook::Statements::Description.new(description) }

    it "outputs the description" do
      allow(toolbox).to receive(:output)
      expect(toolbox).to receive(:output).with("#{description}\n")

      subject.execute(object, metadata)
    end
  end

  describe "runbook__statements__layout" do
    let (:layout) { [:left, :right] }
    let (:title) { "My Stellar Book Title" }
    let (:book) { Runbook::Entities::Book.new(title) }
    let (:object) { Runbook::Statements::Layout.new(layout) }
    let (:layout_panes) { {:left => "%1" , :right => "%2"} }

    before(:each) { book.add(object) }

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the layout statement" do
        msg = "[NOOP] Layout: #{layout.inspect}"
        expect(toolbox).to receive(:output).with(msg)
        expect(subject).to_not receive(:setup_layout)

        subject.execute(object, metadata)
      end
    end

    it "sets up the layout" do
      expect(subject).to receive(:setup_layout).
        with(layout, runbook_title: title).
        and_return(layout_panes)
      subject.execute(object, metadata)
    end

    it "adds the layout to metadata[:layout_panes]" do
      allow(subject).to receive(:setup_layout).and_return(layout_panes)

      subject.execute(object, metadata)

      expect(metadata[:layout_panes]).to eq(layout_panes)
    end
  end

  describe "runbook__statements__monitor" do
    let (:prompt) { "Sky blue?" }
    let (:cmd) { "echo 'hi'" }
    let (:object) do
      Runbook::Statements::Monitor.new(cmd: cmd, prompt: prompt)
    end

    it "outputs the command with instructions" do
      msg1 = "Run the following in a separate pane:"
      msg2 = "`#{cmd}`"
      expect(toolbox).to receive(:output).with(msg1).ordered
      expect(toolbox).to receive(:output).with(msg2).ordered
      expect(toolbox).to receive(:yes?).and_return(true)

      subject.execute(object, metadata)
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the monitor statement" do
        msg = "[NOOP] Prompt: #{prompt}"
        allow(toolbox).to receive(:output)
        expect(toolbox).to receive(:output).with(msg)
        expect(toolbox).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "auto" do
      let(:metadata_override) { {auto: true} }

      it "outputs auto text for the monitor statement" do
        skip_msg = "Skipping confirmation (auto): #{prompt}"
        allow(toolbox).to receive(:output)
        expect(toolbox).to receive(:output).with(skip_msg)
        expect(toolbox).to_not receive(:yes?)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is affirmative" do
      let (:prompt_result) { true }

      it "does not exit" do
        allow(toolbox).to receive(:output)
        expect(
          toolbox
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(toolbox).to_not receive(:exit)

        subject.execute(object, metadata)
      end
    end

    context "when prompt is not affirmative" do
      let (:prompt_result) { false }

      it "exits" do
        allow(toolbox).to receive(:output)
        expect(
          toolbox
        ).to receive(:yes?).with(prompt).and_return(prompt_result)
        expect(toolbox).to receive(:exit).with(1)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__statements__note" do
    let (:note) { "My note..." }
    let (:object) { Runbook::Statements::Note.new(note) }

    it "outputs the note" do
      expect(toolbox).to receive(:output).with("Note: #{note}")

      subject.execute(object, metadata)
    end
  end

  describe "runbook__statements__notice" do
    let (:notice) { "Warning..." }
    let (:object) { Runbook::Statements::Notice.new(notice) }

    it "outputs the notice" do
      expect(toolbox).to receive(:warn).with("Notice: #{notice}")

      subject.execute(object, metadata)
    end
  end

  describe "runbook__statements__ruby_command" do
    let (:block) { ->(object, metadata) { raise "This happened" } }
    let (:object) { Runbook::Statements::RubyCommand.new(&block) }

    it "runs the block" do
      expect do
        subject.execute(object, metadata)
      end.to raise_error("This happened")
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the ruby command statement" do
        msg1 = "[NOOP] Run the following Ruby block:\n"
        expect(toolbox).to receive(:output).with(msg1)
        msg2 = "```ruby\nlet (:block) { ->(object, metadata) { raise \"This happened\" } }\n```\n"
        expect(toolbox).to receive(:output).with(msg2)
        expect(subject).to_not receive(:instance_exec)

        subject.execute(object, metadata)
      end

      context "when ::MethodSource::SourceNotFoundError is raised" do
        it "prints 'Unable to retrieve source code'" do
          expect(block).to receive(:source) do
            raise ::MethodSource::SourceNotFoundError
          end
          msg1 = "[NOOP] Run the following Ruby block:\n"
          expect(toolbox).to receive(:output).with(msg1)
          msg2 = "Unable to retrieve source code"
          expect(toolbox).to receive(:output).with(msg2)

          subject.execute(object, metadata)
        end
      end
    end
  end

  describe "runbook__statements__tmux_command" do
    let (:cmd) { "echo 'hi'" }
    let (:pane) { :pane1 }
    let (:pane_id) { "pane_id" }
    let (:layout_panes) { {:pane1 => pane_id} }
    let(:metadata_override) { {layout_panes: layout_panes} }
    let (:object) do
      Runbook::Statements::TmuxCommand.new(cmd, pane)
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the tmux command statement" do
        msg = "[NOOP] Run: `echo 'hi'` in pane pane1"
        expect(toolbox).to receive(:output).with(msg)
        expect(subject).to_not receive(:send_keys)

        subject.execute(object, metadata)
      end
    end

    it "executes the command in the target pane" do
      expect(subject).to receive(:send_keys).with(cmd, pane_id)
      subject.execute(object, metadata)
    end
  end

  describe "runbook__statements__wait" do
    let (:time) { 60 }
    let (:object) { Runbook::Statements::Wait.new(time) }

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the wait statement" do
        msg = "[NOOP] Sleep #{time} seconds"
        expect(toolbox).to receive(:output).with(msg)
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
