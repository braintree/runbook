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
    end

    context "with users and groups" do
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
