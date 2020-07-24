require "spec_helper"
require 'securerandom'

RSpec.describe "runbook tmux integration", type: :aruba do
  let(:runbook_file) { "my_runbook.rb" }
  let(:book_title) { "My Runbook" }
  let(:repo_file) {
    Runbook::Util::Repo._file(book_title)
  }
  let(:stored_pose_file) {
    Runbook::Util::StoredPose._file(book_title)
  }

  around(:all) do |example|
    `docker build --rm -t runbook:latest -f dockerfiles/Dockerfile-runbook .`
    begin
      @cid = `docker create runbook:latest sleep infinity`.strip
      `docker start #{@cid}`
      example.run
    ensure
      `docker stop -t 0 #{@cid}`
      system("docker rm -f #{@cid} 2>&1 1>/dev/null")
    end
  end

  before(:each) { write_file(runbook_file, content) }
  before(:each) do
    run_command("docker cp #{runbook_file} #{@cid}:#{runbook_file}")
  end

  before(:each) do
    run_command("docker exec #{@cid} rm -rf #{repo_file}")
    run_command("docker exec #{@cid} rm -rf #{stored_pose_file}")
  end

  before(:each) do
    run_command("docker exec -t #{@cid} #{command}")
  end

  describe "tmux_command" do
    let(:sentinel_dir) { "/sentinel_files" }
    let(:sentinel_file) { SecureRandom.hex }
    let(:content) do
      <<-RUNBOOK
      Runbook.book "#{book_title}" do
        layout [:runbook, :commands]

        step "Print stuff" do
          tmux_command "mkdir -p #{sentinel_dir}", :commands
          tmux_command "touch #{sentinel_dir}/#{sentinel_file}", :commands
          note "file touched"
        end
      end
      RUNBOOK
    end
    let(:command) do
      "tmux new 'bundle exec exe/runbook exec -a /#{runbook_file}'"
    end

    let(:output_lines) {
      [
        /Note: file touched/,
      ]
    }

    it "executes the command in the specified tmux pane" do
      output_lines.each do |line|
        expect(last_command_started).to have_output(line)
      end

      run_command("docker exec #{@cid} ls #{sentinel_dir}")
      expect(last_command_started).to have_output(sentinel_file)
    end

    context "when single quotes are not escaped" do
      let(:sentinel_file) { "#{SecureRandom.hex}$love" }
      let(:content) do
        <<-RUNBOOK
        Runbook.book "#{book_title}" do
          layout [:runbook, :commands]

          step "Print stuff" do
            tmux_command "mkdir -p #{sentinel_dir}", :commands
            tmux_command "touch '#{sentinel_dir}/#{sentinel_file}'", :commands
            note "file touched"
          end
        end
        RUNBOOK
      end

      it "does not break tmux_command" do
        output_lines.each do |line|
          expect(last_command_started).to have_output(line)
        end

        run_command("docker exec #{@cid} ls #{sentinel_dir}")
        expect(last_command_started).to have_output(sentinel_file)
      end
    end
  end
end
