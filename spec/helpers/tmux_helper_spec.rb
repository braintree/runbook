require "spec_helper"

RSpec.describe Runbook::Helpers::TmuxHelper do
  subject { Class.new { include Runbook::Helpers::TmuxHelper }.new }
  tmux_mutator_methods = [
    :send_keys,
    :_set_window_name,
    :_new_window,
    :_split,
    :_swap_panes,
    :_remove_stale_layouts,
    :_kill_pane,
  ]

  describe "setup_layout" do
    let(:structure) { [:runbook, :other] }
    let(:title) { "My Amazing Runbook" }
    let(:layout_file) { "/tmp/runbook_layout_12345_me_123_%0_amazing_runbook.yml" }
    let(:stored_layout) { {:runbook => "%1", :other => "%3", :new => "%5"} }
    let(:layout_panes) { {:runbook => "%1", :other => "%3"} }
    let(:session_panes) { ["%0", "%1", "%2", "%3", "%4"] }

    before(:each) do
      allow(subject).to receive(:_layout_file).and_return(layout_file)
      allow(subject).to receive(:_setup_layout).and_return(layout_panes)
      allow(subject).to receive(:_session_panes).and_return(session_panes)
      allow(subject).to receive(:_session_layout_files).and_return([])
      allow(File).to receive(:open)
      allow(File).to receive(:delete)
      tmux_mutator_methods.each { |method| allow(subject).to receive(method) }
    end

    it "removes stale layout files" do
      expect(subject).to receive(:_remove_stale_layouts)

      subject.setup_layout(structure, runbook_title: title)
    end

    it "generates a layout file name from _layout_file" do
      expect(subject).to receive(:_layout_file).and_return(layout_file)
      subject.setup_layout(structure, runbook_title: title)
    end

    context "when layout_file exists" do
      before(:each) do
        expect(File).to receive(:exists?).with(layout_file).and_return(true)
      end

      context "when all panes exist" do
        let(:stored_layout) { {:runbook => "%1", :other => "%3"} }
        let(:layout_panes) { {:runbook => "%1", :other => "%3"} }
        let(:session_panes) { ["%0", "%1", "%2", "%3", "%4"] }

        it "returns the stored layout" do
          expect(YAML).to receive(:load_file).with(layout_file).and_return(stored_layout)
          expect(subject).to receive(:_session_panes).and_return(session_panes)
          subject.setup_layout(structure, runbook_title: title)
        end
      end
    end

    context "when layout file does not exist" do
      before(:each) do
        expect(File).to receive(:exists?).with(layout_file).and_return(false)
      end

      it "invokes _setup_layout" do
        expect(subject).to receive(:_setup_layout).and_return(layout_panes)

        subject.setup_layout(structure, runbook_title: title)
      end

      it "writes layout_panes to layout_file" do
        expect(File).to receive(:open).with(layout_file, 'w')

        subject.setup_layout(structure, runbook_title: title)
      end

      it "returns layout_panes" do
        expect(subject).to receive(:_setup_layout).and_return(layout_panes)

        result = subject.setup_layout(structure, runbook_title: title)
        expect(result).to eq(layout_panes)
      end
    end
  end

  describe "kill_all_panes" do
    let(:runbook_pane) { "%23" }
    let(:layout_panes) { {:some => "%45", :runbook => "%23", :thing => "%3"} }

    before(:each) do
      allow(subject).to receive(:_runbook_pane).and_return(runbook_pane)
    end

    it "kills all panes in layout_panes (except the runbook pane)" do
      expect(subject).to receive(:_kill_pane).with("%45")
      expect(subject).to receive(:_kill_pane).with("%3")
      expect(subject).to_not receive(:_kill_pane).with(runbook_pane)

      subject.kill_all_panes(layout_panes)
    end
  end

  describe "_slug" do
    let(:inputs) { [
      "My Runbook Title",
      "my Runbook title",
      "OTHER Runbook TITLE",
      "some      Runbook TITLE",
    ] }

    let(:outputs) { [
      "my-runbook-title",
      "my-runbook-title",
      "other-runbook-title",
      "some-runbook-title",
    ] }

    it "returns a slugified version of its argument" do
      inputs.each_with_index do |input, index|
        expect(subject._slug(input)).to eq(outputs[index])
      end
    end
  end

  describe "_remove_stale_layouts" do
    let(:session_panes) { ["%0", "%1", "%2", "%3", "%4"] }
    let(:fresh_session_layout_files) do
      [
        "/tmp/runbook_layout_25996_pair_2716_%1_example-layout-book.yml",
        "/tmp/runbook_layout_25996_pair_2716_%4_example-layout-book.yml",
      ]
    end
    let(:stale_session_layout_files) do
      [
        "/tmp/runbook_layout_25996_pair_2716_%14_example-layout-book.yml",
        "/tmp/runbook_layout_25996_pair_2716_%44_example-layout-book.yml",
      ]
    end
    let(:session_layout_files) do
      fresh_session_layout_files + stale_session_layout_files
    end

    before(:each) do
      allow(subject).to receive(:_session_panes).and_return(session_panes)
      allow(
        subject
      ).to receive(:_session_layout_files).and_return(session_layout_files)
    end

    it "removes old layout files" do
      stale_session_layout_files.each do |file|
        expect(File).to receive(:delete).with(file)
      end
      fresh_session_layout_files.each do |file|
        expect(File).to_not receive(:delete)
      end

      subject._remove_stale_layouts
    end
  end

  describe "_setup_layout" do
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
