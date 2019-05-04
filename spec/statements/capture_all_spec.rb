require "spec_helper"

RSpec.describe Runbook::Statements::CaptureAll do
  let(:cmd) { "echo 'hi'" }
  let(:into) { :capture_result }
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
  let(:strip) { false }
  let(:capture_all) {
    Runbook::Statements::CaptureAll.new(
      cmd,
      into: into,
      ssh_config: ssh_config,
      raw: raw,
      strip: strip,
    )
  }

  it "has a command" do
    expect(capture_all.cmd).to eq(cmd)
  end

  it "has an into" do
    expect(capture_all.into).to eq(into)
  end

  it "has an ssh_config" do
    expect(capture_all.ssh_config).to eq(ssh_config)
  end

  it "has a raw param" do
    expect(capture_all.raw).to eq(raw)
  end

  it "has a strip param" do
    expect(capture_all.strip).to eq(strip)
  end

  describe "default_values" do
    let(:capture_all) { Runbook::Statements::CaptureAll.new(cmd, into: into) }
    it "sets defaults for ssh_config" do
      expect(capture_all.ssh_config).to be_nil
    end

    it "sets defaults for raw" do
      expect(capture_all.raw).to be_falsey
    end

    it "sets defaults for strip" do
      expect(capture_all.strip).to be_truthy
    end
  end
end
