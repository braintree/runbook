require "spec_helper"

RSpec.describe Runbook::Statements::Command do
  let(:cmd) { "echo 'hi'" }
  let(:ssh_config) {
    {
      servers: ["server1.prod"],
      parallelization: {
        strategy: :groups,
        limit: 2,
        wait: 2,
      },
      path: "/home/bobby_mcgee",
      user: "bobby_mcgee",
      group: "bobby_mcgee",
      env: {rails_env: "production"},
      umask: "077",
    }
  }
  let(:raw) { true }
  let(:command) {
    Runbook::Statements::Command.new(
      cmd,
      ssh_config: ssh_config,
      raw: raw,
    )
  }

  it "has a command" do
    expect(command.cmd).to eq(cmd)
  end

  it "has an ssh_config" do
    expect(command.ssh_config).to eq(ssh_config)
  end

  it "has a raw param" do
    expect(command.raw).to eq(raw)
  end

  describe "default_values" do
    let(:command) { Runbook::Statements::Command.new(cmd) }
    it "sets defaults for ssh_config" do
      expect(command.ssh_config).to be_nil
    end

    it "sets defaults for raw" do
      expect(command.raw).to be_falsey
    end
  end
end
