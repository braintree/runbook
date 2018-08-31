require "spec_helper"

RSpec.describe Runbook::Helpers::TmuxHelper do
  subject { Class.new { include Runbook::Helpers::TmuxHelper }.new }
  tmux_mutator_methods = [
    :send_keys,
    :_set_window_name,
    :_new_window,
    :_split,
    :_swap_panes,
  ]

  describe "setup_layout" do
    let(:runbook_pane_id) { "%19" }
    before(:each) do
      allow(subject).to receive(:_runbook_pane).and_return(runbook_pane_id)
      tmux_mutator_methods.each { |method| allow(subject).to receive(method) }
    end

    context "with identity" do
      let(:structure) { [] }

      it "does not execute any tmux commands" do
        (tmux_mutator_methods).each do |method|
          expect(subject).to_not receive(method)
        end

        subject._setup_layout(structure)
      end
    end

    context "with configurated pane" do
      let(:name) { :runbook_pane }
      let(:directory) { "/some/directory" }
      let(:command) { "echo hi" }
      let(:structure) do
        [{
          name: name,
          directory: directory,
          command: command,
          runbook_pane: true,
        }]
      end

      it "initializes the pane" do
        expect(subject).to receive(:send_keys).with("cd #{directory}", runbook_pane_id)
        expect(subject).to receive(:send_keys).with(command, runbook_pane_id)

        layout_panes = subject._setup_layout(structure)

        expect(layout_panes).to eq({name => runbook_pane_id})
      end
    end

    context "with two pane vertical structure" do
      let(:pane_2_id) { "%20" }
      let(:structure) do
        [:pane1, :pane2]
      end

      it "returns a map of names to pane ids" do
        expect(subject).to receive(:_split).with(runbook_pane_id, 0, 50).and_return(pane_2_id)

        layout_panes = subject._setup_layout(structure)

        expect(layout_panes).to eq(
          {pane1: runbook_pane_id, pane2: pane_2_id}
        )
      end
    end

    context "with two pane horizontal structure" do
      let(:pane_2_id) { "%20" }
      let(:structure) do
        [[:pane1, :pane2]]
      end

      it "returns a map of names to pane ids" do
        expect(subject).to receive(:_split).with(runbook_pane_id, 1, 50).and_return(pane_2_id)

        layout_panes = subject._setup_layout(structure)

        expect(layout_panes).to eq(
          {pane1: runbook_pane_id, pane2: pane_2_id}
        )
      end
    end

    context "with three panes" do
      let(:pane_2_id) { "%20" }
      let(:pane_3_id) { "%21" }
      let(:structure) do
        [:pane1, :pane2, :pane3]
      end

      it "performs 2 splits" do
        expect(subject).to receive(:_split).with(runbook_pane_id, 0, 67).and_return(pane_2_id)
        expect(subject).to receive(:_split).with(pane_2_id, 0, 50).and_return(pane_3_id)

        layout_panes = subject._setup_layout(structure)

        expect(layout_panes).to eq(
          {pane1: runbook_pane_id, pane2: pane_2_id, pane3: pane_3_id}
        )
      end
    end

    context "with specified runbook pane" do
      let(:pane_2_id) { "%20" }
      let(:command) { "echo hi" }
      let(:structure) do
        [
          {name: :pane1, command: command},
          {name: :runbook_pane, runbook_pane: true},
        ]
      end

      it "swaps the panes" do
        expect(subject).to receive(:_split).with(runbook_pane_id, 0, 50).and_return(pane_2_id)
        expect(subject).to receive(:_swap_panes).with(pane_2_id, runbook_pane_id)
        expect(subject).to receive(:send_keys).with(command, pane_2_id)

        layout_panes = subject._setup_layout(structure)

        expect(layout_panes).to eq(
          {pane1: pane_2_id, runbook_pane: runbook_pane_id}
        )
      end
    end

    context "with uneven size structure" do
      let(:pane_2_id) { "%20" }
      let(:structure) do
        [[
          {
            :pane1 => 1,
            :pane2 => 3,
          }
        ]]
      end

      it "splits the structure appropriately" do
        expect(subject).to receive(:_split).with(runbook_pane_id, 2, 75).and_return(pane_2_id)

        subject._setup_layout(structure)
      end
    end

    context "with single window" do
      let(:window_name) { :window1 }
      let(:structure) do
        {
          window_name => [:pane1, :pane2],
        }
      end

      it "renames the current_window" do
        expect(subject).to receive(:_rename_window).with(window_name)
        expect(subject).to_not receive(:_new_window)

        subject._setup_layout(structure)
      end
    end

    context "with multiple windows" do
      let (:window_1) { "w1" }
      let (:window_2) { "w2" }
      let(:structure) do
        {
          window_1 => [:pane],
          window_2 => [:left, :right],
        }
      end

      it "creates the new window" do
        expect(subject).to receive(:_rename_window).with(window_1)
        expect(subject).to receive(:_new_window).with(window_2)

        subject._setup_layout(structure)
      end
    end
  end
end
