require "spec_helper"

RSpec.describe Runbook::Runs::SSHKit do
  subject { Runbook::Runs::SSHKit }
  let (:metadata_override) { {} }
  let (:parent) { Runbook::Entities::Step.new }
  let (:toolbox) { instance_double("Runbook::Toolbox") }
  let (:metadata) {
    {
      noop: false,
      auto: false,
      start_at: 0,
      toolbox: toolbox,
      depth: 1,
      index: 2,
      position: "3.3",
    }.merge(metadata_override)
  }

  before(:each) { object.parent = parent }

  describe "runbook__entities__assert" do
    let (:cmd) { "echo 'hi'" }
    let (:interval) { 7 }
    let (:object) do
      Runbook::Statements::Assert.new(cmd, interval: interval)
    end

    it "runs cmd until it returns true" do
      test_args = [:echo, "'hi'"]
      ssh_config = object.parent.ssh_config
      expect(
        subject
      ).to receive(:with_ssh_config).with(ssh_config).and_call_original
      expect_any_instance_of(
        SSHKit::Backend::Abstract
      ).to receive(:test).with(*test_args).and_return(true)
      expect(subject).to_not receive(:sleep)

      subject.execute(object, metadata)
    end

    context "with cmd_ssh_config set" do
      let(:cmd_ssh_config) do
        {servers: ["host.stg"], parallelization: {}}
      end
      let (:object) do
        Runbook::Statements::Assert.new(
          cmd,
          cmd_ssh_config: cmd_ssh_config
        )
      end

      it "uses the cmd_ssh_config" do
        test_args = [:echo, "'hi'"]
        expect(
          subject
        ).to receive(:with_ssh_config).with(cmd_ssh_config).and_call_original
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:test).with(*test_args).and_return(true)
        expect(subject).to_not receive(:sleep)

        subject.execute(object, metadata)
      end
    end

    context "with raw true" do
      let(:raw) { true }
      let (:object) do
        Runbook::Statements::Assert.new(cmd, cmd_raw: raw)
      end

      it "runs runs test with the raw commmand string" do
        test_args = ["echo 'hi'"]
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:test).with(*test_args).and_return(true)

        subject.execute(object, metadata)
      end
    end

    context "when assertion times out" do
      let!(:time) { Time.now }
      let (:timeout) { 1 }
      before(:each) do
        expect(Time).to receive(:now).and_return(time, time + timeout + 1)
      end
      let (:object) do
        Runbook::Statements::Assert.new(cmd, timeout: timeout)
      end

      it "raises an ExecutionError" do
        test_args = [:echo, "'hi'"]
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:test).with(*test_args).and_return(false)
        expect(subject).to_not receive(:sleep)

        error_msg = "Error! Assertion `#{cmd}` failed"
        expect(toolbox).to receive(:error).with(error_msg)
        expect do
          subject.execute(object, metadata)
        end.to raise_error Runbook::Runner::ExecutionError, error_msg
      end

      context "when timeout_cmd is set" do
        let (:timeout_cmd) { "echo 'timed out!'" }
        let (:object) do
          Runbook::Statements::Assert.new(
            cmd,
            timeout: timeout,
            timeout_cmd: timeout_cmd
          )
        end

        before(:each) do
          test_args = [:echo, "'hi'"]
          expect_any_instance_of(
            SSHKit::Backend::Abstract
          ).to receive(:test).with(*test_args).and_return(false)
          allow(subject).to receive(:with_ssh_config).and_call_original
        end

        it "calls the timeout_cmd" do
          timeout_cmd_args = [:echo, "'timed out!'"]
          ssh_config = object.parent.ssh_config
          expect(toolbox).to receive(:error)
          expect(
            subject
          ).to receive(:with_ssh_config).with(ssh_config).and_call_original
          expect_any_instance_of(
            SSHKit::Backend::Abstract
          ).to receive(:execute).with(*timeout_cmd_args)

          expect do
            subject.execute(object, metadata)
          end.to raise_error Runbook::Runner::ExecutionError
        end

        context "when timeout_cmd_ssh_config is set" do
          let (:timeout_cmd_ssh_config) do
            {servers: ["server01.stg"], parallelization: {}}
          end
          let (:object) do
            Runbook::Statements::Assert.new(
              cmd,
              timeout: timeout,
              timeout_cmd: timeout_cmd,
              timeout_cmd_ssh_config: timeout_cmd_ssh_config,
            )
          end

          it "calls the timeout_cmd with timeout_cmd_ssh_config" do
            timeout_cmd_args = [:echo, "'timed out!'"]
            expect(toolbox).to receive(:error)
            expect(subject).to receive(:with_ssh_config).
              with(timeout_cmd_ssh_config).
              and_call_original
            expect_any_instance_of(
              SSHKit::Backend::Abstract
            ).to receive(:execute).with(*timeout_cmd_args)

            expect do
              subject.execute(object, metadata)
            end.to raise_error Runbook::Runner::ExecutionError
          end
        end

        context "when timeout_cmd_raw is set to true" do
          let(:raw) { true }
          let (:object) do
            Runbook::Statements::Assert.new(
              cmd,
              timeout: timeout,
              timeout_cmd: timeout_cmd,
              timeout_cmd_raw: raw,
            )
          end


          it "calls the timeout_cmd with raw command string" do
            timeout_cmd_args = ["echo 'timed out!'"]
            expect(toolbox).to receive(:error)
            expect_any_instance_of(
              SSHKit::Backend::Abstract
            ).to receive(:execute).with(*timeout_cmd_args)

            expect do
              subject.execute(object, metadata)
            end.to raise_error Runbook::Runner::ExecutionError
          end
        end
      end
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the assert statement" do
        msg = "[NOOP] Assert: `#{cmd}` returns 0"
        msg += " (running every #{interval} second(s))"
        expect(toolbox).to receive(:output).with(msg)
        expect(subject).to_not receive(:with_ssh_config)

        subject.execute(object, metadata)
      end

      context "when timeout > 0" do
        let (:timeout) { 1 }
        let (:object) do
          Runbook::Statements::Assert.new(cmd, timeout: timeout)
        end

        it "outputs the noop text for the timeout" do
          msg = "after #{timeout} seconds, exit"
          allow(toolbox).to receive(:output)
          expect(toolbox).to receive(:output).with(msg)

          subject.execute(object, metadata)
        end

        context "when timeout_cmd is specified" do
          let (:timeout_cmd) { "./notify_everyone" }
          let (:object) do
            Runbook::Statements::Assert.new(
              cmd,
              timeout: timeout,
              timeout_cmd: timeout_cmd,
            )
          end

          it "outputs the noop text for the timeout_cmd" do
            msg = "after #{timeout} seconds, run `#{timeout_cmd}` and exit"
            allow(toolbox).to receive(:output)
            expect(toolbox).to receive(:output).with(msg)

            subject.execute(object, metadata)
          end
        end
      end
    end
  end

  describe "runbook__entities__command" do
    let (:cmd) { "echo 'hi'" }
    let (:object) { Runbook::Statements::Command.new(cmd) }

    before(:each) do
      allow(toolbox).to receive(:output)
    end

    it "runs cmd" do
      execute_args = [:echo, "'hi'"]
      ssh_config = object.parent.ssh_config
      expect(
        subject
      ).to receive(:with_ssh_config).with(ssh_config).and_call_original
      expect_any_instance_of(
        SSHKit::Backend::Abstract
      ).to receive(:execute).with(*execute_args)

      subject.execute(object, metadata)
    end

    context "with ssh_config set" do
      let(:ssh_config) do
        {servers: ["host.stg"], parallelization: {}}
      end
      let (:object) do
        Runbook::Statements::Command.new(cmd, ssh_config: ssh_config)
      end

      it "uses the ssh_config" do
        execute_args = [:echo, "'hi'"]
        expect(
          subject
        ).to receive(:with_ssh_config).with(ssh_config).and_call_original
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:execute).with(*execute_args)

        subject.execute(object, metadata)
      end
    end

    context "with raw true" do
      let(:raw) { true }
      let (:object) do
        Runbook::Statements::Command.new(cmd, raw: raw)
      end

      it "executes the raw command string" do
        execute_args = ["echo 'hi'"]
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:execute).with(*execute_args)

        subject.execute(object, metadata)
      end
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the command statement" do
        msg = "[NOOP] Run: `#{cmd}`"
        expect(toolbox).to receive(:output).with(msg)
        expect(subject).to_not receive(:with_ssh_config)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__entities__capture" do
    let (:cmd) { "echo 'hi'" }
    let (:into) { :result }
    let(:result) { "hi" }
    let (:object) { Runbook::Statements::Capture.new(cmd, into: into) }

    before(:each) do
      allow(toolbox).to receive(:output)
    end

    it "captures cmd" do
      capture_args = [:echo, "'hi'", {:strip => true}]
      ssh_config = object.parent.ssh_config
      expect(
        subject
      ).to receive(:with_ssh_config).with(ssh_config).and_call_original
      expect_any_instance_of(
        SSHKit::Backend::Abstract
      ).to receive(:capture).with(*capture_args).and_return(result)

      subject.execute(object, metadata)
      expect(object.parent.send(into)).to eq(result)
    end

    context "with ssh_config set" do
      let(:ssh_config) do
        {servers: ["host.stg"], parallelization: {}}
      end
      let (:object) do
        Runbook::Statements::Capture.new(
          cmd,
          into: into,
          ssh_config: ssh_config,
        )
      end

      it "uses the ssh_config" do
        capture_args = [:echo, "'hi'", {:strip => true}]
        expect(
          subject
        ).to receive(:with_ssh_config).with(ssh_config).and_call_original
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:capture).with(*capture_args)

        subject.execute(object, metadata)
      end
    end

    context "with raw true" do
      let(:raw) { true }
      let (:object) do
        Runbook::Statements::Capture.new(cmd, into: into, raw: raw)
      end

      it "executes the raw command string" do
        capture_args = ["echo 'hi'", {:strip => true}]
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:capture).with(*capture_args)

        subject.execute(object, metadata)
      end
    end

    context "with strip false" do
      let(:strip) { false }
      let (:object) do
        Runbook::Statements::Capture.new(cmd, into: into, strip: strip)
      end

      it "executes the raw command string" do
        capture_args = [:echo, "'hi'", {:strip => false}]
        expect_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:capture).with(*capture_args)

        subject.execute(object, metadata)
      end
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the capture statement" do
        msg = "[NOOP] Capture: `#{cmd}` into #{into}"
        expect(toolbox).to receive(:output).with(msg)
        expect(subject).to_not receive(:with_ssh_config)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__entities__download" do
    let (:from) { "/var/log/auth.log" }
    let (:to) { "auth.log" }
    let(:options) { {log_percent: 25} }
    let(:download_args) { [from, to, options] }
    let (:object) {
      Runbook::Statements::Download.new(from, to: to, options: options)
    }

    before(:each) do
      allow(toolbox).to receive(:output)
    end

    it "downloads the file" do
      ssh_config = object.parent.ssh_config
      expect(
        subject
      ).to receive(:with_ssh_config).with(ssh_config).and_call_original
      expect_any_instance_of(
        SSHKit::Backend::Local
      ).to receive(:download!).with(*download_args)

      subject.execute(object, metadata)
    end

    context "with ssh_config set" do
      let(:ssh_config) do
        {servers: ["host.stg"], parallelization: {}}
      end
      let (:object) do
        Runbook::Statements::Download.new(
          from,
          to: to,
          options: options,
          ssh_config: ssh_config,
        )
      end

      it "uses the ssh_config" do
        expect(
          subject
        ).to receive(:with_ssh_config).with(ssh_config).and_call_original
        expect_any_instance_of(
          SSHKit::Backend::Netssh
        ).to receive(:download!).with(*download_args)

        subject.execute(object, metadata)
      end
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the download statement" do
        msg = "[NOOP] Download: #{from} to #{to} with options #{options}"
        expect(toolbox).to receive(:output).with(msg)
        expect(subject).to_not receive(:with_ssh_config)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__entities__upload" do
    let (:from) { "customer_list.txt" }
    let (:to) { "/home/bozo/customer_list.txt" }
    let(:options) { {log_percent: 25} }
    let(:upload_args) { [from, to, options] }
    let (:object) {
      Runbook::Statements::Upload.new(from, to: to, options: options)
    }

    before(:each) do
      allow(toolbox).to receive(:output)
    end

    it "uploads the file" do
      ssh_config = object.parent.ssh_config
      expect(
        subject
      ).to receive(:with_ssh_config).with(ssh_config).and_call_original
      expect_any_instance_of(
        SSHKit::Backend::Local
      ).to receive(:upload!).with(*upload_args)

      subject.execute(object, metadata)
    end

    context "with ssh_config set" do
      let(:ssh_config) do
        {servers: ["host.stg"], parallelization: {}}
      end
      let (:object) do
        Runbook::Statements::Upload.new(
          from,
          to: to,
          options: options,
          ssh_config: ssh_config,
        )
      end

      it "uses the ssh_config" do
        expect(
          subject
        ).to receive(:with_ssh_config).with(ssh_config).and_call_original
        expect_any_instance_of(
          SSHKit::Backend::Netssh
        ).to receive(:upload!).with(*upload_args)

        subject.execute(object, metadata)
      end
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the upload statement" do
        msg = "[NOOP] Upload: #{from} to #{to} with options #{options}"
        expect(toolbox).to receive(:output).with(msg)
        expect(subject).to_not receive(:with_ssh_config)

        subject.execute(object, metadata)
      end
    end
  end
end
