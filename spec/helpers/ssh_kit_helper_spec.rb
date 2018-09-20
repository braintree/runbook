require "spec_helper"

RSpec.describe Runbook::Helpers::SSHKitHelper do
  subject { Class.new { include Runbook::Helpers::SSHKitHelper }.new }

  describe "ssh_kit_command" do
    let(:cmd) { "ls -l /home/bigbird" }

    it "returns an array with first word symbolized" do
      expect(
        subject.ssh_kit_command(cmd)
      ).to eq([:ls, "-l /home/bigbird"])
    end

    it "works when no command arguments are given" do
      expect(subject.ssh_kit_command("ls")).to eq([:ls, nil])
    end

    it "returns and array with cmd when raw is true" do
      expect(subject.ssh_kit_command(cmd, raw: true)).to eq([cmd])
    end
  end

  describe "find_ssh_config" do
    let(:metadata) { {} }
    let(:blank_ssh_config) {
      Runbook::Extensions::SSHConfig.blank_ssh_config
    }
    let(:stmt_ssh_config) {
      blank_ssh_config[:servers] << "stmt_server.prod"
    }
    let(:object) {
      Runbook::Statements::Command.new("ls")
    }
    let(:step_server) { "step_server.prod" }
    let(:step) {
      Runbook::Entities::Step.new("Step 1")
    }
    let(:section_server) { "section_server.prod" }
    let(:section) {
      Runbook::Entities::Section.new("Section 1")
    }

    before(:each) { section.add(step); step.add(object) }

    context "when no ssh_configs are set" do
      it "uses a blank config" do
        expect(
          subject.find_ssh_config(object)
        ).to eq(blank_ssh_config)
      end
    end

    context "when section ssh_config is set" do
      before(:each) { section.dsl.server section_server }

      it "uses the section config" do
        expect(
          subject.find_ssh_config(object)[:servers]
        ).to eq([section_server])
      end

      context "when step ssh_config is set" do
        before(:each) { step.dsl.server step_server }

        it "uses the step config" do
          expect(
            subject.find_ssh_config(object)[:servers]
          ).to eq([step_server])
        end

        context "when statement ssh_config is set" do
          let(:object) do
            Runbook::Statements::Command.new("ls", ssh_config: stmt_ssh_config)
          end

          it "uses the statement config" do
            expect(
              subject.find_ssh_config(object)
            ).to eq(stmt_ssh_config)
          end
        end

        context "when statement is an assert statement" do
          let(:object) do
            Runbook::Statements::Assert.new("ls", cmd_ssh_config: stmt_ssh_config)
          end

          it "uses the statement cmd_ssh_config" do
            expect(
              subject.find_ssh_config(object, :cmd_ssh_config)
            ).to eq(stmt_ssh_config)
          end
        end
      end
    end
  end

  describe "with_ssh_config" do
    let(:servers) { [] }
    let(:parallelization) { {strategy: :parallel} }
    let(:additional_config) { {} }
    let(:ssh_config) do
      {
        servers: servers,
        parallelization: parallelization,
      }.merge(additional_config)
    end

    context "servers" do
      context "when servers is empty" do
        let(:servers) { [] }

        it "passes :local to Coordinator.new" do
          expect(
            SSHKit::Coordinator
          ).to receive(:new).with(:local).and_call_original

          subject.with_ssh_config(ssh_config) {}
        end
      end

      context "when servers equals [:local]" do
        let(:servers) { [:local] }

        it "passes :local to Coordinator.new" do
          expect(
            SSHKit::Coordinator
          ).to receive(:new).with(:local).and_call_original
          subject.with_ssh_config(ssh_config) {}
        end
      end

      context "when servers contains a host" do
        let(:servers) { ["host1.stg"] }

        it "passes the host to Coordinator.new" do
          expect(
            SSHKit::Coordinator
          ).to receive(:new).with(["host1.stg"]).and_call_original
          subject.with_ssh_config(ssh_config) {}
        end
      end
    end

    context "coordinator options" do
      context "when :sequence strategy is passed" do
        let(:parallelization) { {strategy: :sequence} }

        it "passes the strategy to the coordinator's each method" do
          each_args = [in: :sequence]

          expect_any_instance_of(
            SSHKit::Coordinator
          ).to receive(:each).with(*each_args).and_call_original
          subject.with_ssh_config(ssh_config) {}
        end
      end

      context "when :wait attribute is passed" do
        let(:parallelization) { {strategy: :sequence, wait: 1} }

        it "passes the wait attribute to the coordinator's each method" do
          each_args = [in: :sequence, wait: 1]
          expect_any_instance_of(
            SSHKit::Coordinator
          ).to receive(:each).with(*each_args).and_call_original

          subject.with_ssh_config(ssh_config) {}
        end
      end

      context "when :limit and :wait attributes are passed" do
        let(:parallelization) { {strategy: :groups, limit: 2, wait: 1} }

        it "passes limit and wait attributes to coordinator's each method" do
          each_args = [in: :groups, limit: 2, wait: 1]
          expect_any_instance_of(
            SSHKit::Coordinator
          ).to receive(:each).with(*each_args).and_call_original

          subject.with_ssh_config(ssh_config) {}
        end
      end

      context "when no strategy is passed" do
        let(:parallelization) { {} }

        it "does not pass an :in option" do
          expect_any_instance_of(
            SSHKit::Coordinator
          ).to receive(:each).with({}).and_call_original
          subject.with_ssh_config(ssh_config) {}
        end
      end
    end

    context "with users and groups" do
      before(:each) do
        allow_any_instance_of(
          SSHKit::Backend::Abstract
        ).to receive(:execute).with(/whoami/, any_args)
      end

      context "with user specified" do
        let(:additional_config) { {user: "root"} }

        it "passes the user to the coordinator" do
          as_args = [user: "root", group: nil]
          expect_any_instance_of(
            SSHKit::Backend::Abstract
          ).to receive(:as).with(*as_args).and_call_original

          subject.with_ssh_config(ssh_config) {}
        end
      end

      context "with user and group specified" do
        let(:additional_config) { {user: "root", group: "root"} }

        it "passes the user and group to the coordinator" do
          as_args = [user: "root", group: "root"]
          expect_any_instance_of(
            SSHKit::Backend::Abstract
          ).to receive(:as).with(*as_args).and_call_original

          subject.with_ssh_config(ssh_config) {}
        end
      end
    end

    context "with environment" do
      context "with env specified" do
        let(:additional_config) { {env: {rails_env: "test"}} }

        it "passes the user to the coordinator" do
          with_args = [rails_env: "test"]
          expect_any_instance_of(
            SSHKit::Backend::Abstract
          ).to receive(:with).with(*with_args).and_call_original

          subject.with_ssh_config(ssh_config) {}
        end
      end
    end

    context "with path" do
      context "with path specified" do
        let(:additional_config) { {path: "/home/"} }

        it "passes the path to the coordinator" do
          within_args = ["/home/"]
          expect_any_instance_of(
            SSHKit::Backend::Abstract
          ).to receive(:within).with(*within_args).and_call_original

          subject.with_ssh_config(ssh_config) {}
        end
      end
    end

    context "with umask" do
      let(:umask) { "077" }
      let(:additional_config) { {umask: umask} }

      it "temporarily sets the umask" do
        old_umask = SSHKit.config.umask
        expect(SSHKit.config).to receive(:umask=).with(umask).ordered.and_call_original
        expect(SSHKit.config).to receive(:umask=).with(old_umask).ordered.and_call_original

        internal_umask = nil
        subject.with_ssh_config(ssh_config) {
          internal_umask = SSHKit.config.umask
        }

        expect(internal_umask).to eq(umask)
        expect(SSHKit.config.umask).to eq(old_umask)
      end
    end
  end
end
