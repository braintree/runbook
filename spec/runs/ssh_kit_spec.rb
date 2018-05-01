require "spec_helper"

RSpec.describe "Runbook::Runs::SSHKit" do
  subject { Runbook::Runs::SSHKit.new }
  let (:metadata_override) { {} }
  let (:parent) { Runbook::Entities::Step.new }
  let (:metadata) {
    {
      noop: false,
      auto: false,
      start_at: 0,
      depth: 1,
      index: 2,
      parent: parent,
      position: "3.3",
    }.merge(metadata_override)
  }

  before(:each) do
    allow(subject).to receive(:_output)
    allow(subject).to receive(:_warn)
    allow(subject).to receive(:_error)
    allow(subject).to receive(:_exit)
  end

  describe "runbook__entities__assert" do
    let (:cmd) { "echo 'hi'" }
    let (:interval) { 7 }
    let (:object) do
      Runbook::Statements::Assert.new(cmd, interval: interval)
    end

    it "runs cmd until it returns true" do
      test_args = [:echo, "'hi'"]
      ssh_config = metadata[:parent].ssh_config
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
        expect(subject).to receive(:_error).with(error_msg)
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
          expect(subject).to receive(:with_ssh_config).and_call_original
        end

        it "calls the timeout_cmd" do
          timeout_cmd_args = [:echo, "'timed out!'"]
          ssh_config = metadata[:parent].ssh_config
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
      end
    end

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the assert statement" do
        msg = "[NOOP] Assert: #{cmd} returns 0"
        msg += " (running every #{interval} second(s))"
        expect(subject).to receive(:_output).with(msg)
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
          expect(subject).to receive(:_output).with(msg)

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
            expect(subject).to receive(:_output).with(msg)

            subject.execute(object, metadata)
          end
        end
      end
    end
  end

  describe "runbook__entities__command" do
    let (:cmd) { "echo 'hi'" }
    let (:object) { Runbook::Statements::Command.new(cmd) }

    it "runs cmd" do
      execute_args = [:echo, "'hi'"]
      ssh_config = metadata[:parent].ssh_config
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

    context "noop" do
      let(:metadata_override) { {noop: true} }

      it "outputs the noop text for the command statement" do
        msg = "[NOOP] Run: #{cmd}"
        expect(subject).to receive(:_output).with(msg)
        expect(subject).to_not receive(:with_ssh_config)

        subject.execute(object, metadata)
      end
    end
  end

  describe "runbook__entities__ruby_command" do
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
        msg1 = "\n[NOOP] Run the following Ruby block:\n"
        expect(subject).to receive(:_output).with(msg1)
        msg2 = "```ruby\nlet (:block) { ->(object, metadata) { raise \"This happened\" } }\n```\n"
        expect(subject).to receive(:_output).with(msg2)
        expect(subject).to_not receive(:instance_exec)

        subject.execute(object, metadata)
      end
    end
  end
end
