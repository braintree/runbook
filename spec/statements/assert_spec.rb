require "spec_helper"

RSpec.describe Runbook::Statements::Assert do
  let(:cmd) { "ps aux | grep [n]ginx" }
  let(:cmd_ssh_config) { {servers: ["server.stg"], parallelization: {}} }
  let(:interval) { 0.5 }
  let(:timeout) { 600 }
  let(:exec_on_timeout) { %Q{mail -S "Error" me@me.com} }
  let(:exec_on_timeout_ssh_config) { {servers: [], parallelization: {}} }
  let(:assert) do
    Runbook::Statements::Assert.new(
      cmd,
      cmd_ssh_config: cmd_ssh_config,
      interval: interval,
      timeout: timeout,
      exec_on_timeout: exec_on_timeout,
      exec_on_timeout_ssh_config: exec_on_timeout_ssh_config,
    )
  end

  it "has a cmd" do
    expect(assert.cmd).to eq(cmd)
  end

  it "has a cmd_ssh_config" do
    expect(assert.cmd_ssh_config).to eq(cmd_ssh_config)
  end

  it "has an interval" do
    expect(assert.interval).to eq(interval)
  end

  it "has a timeout" do
    expect(assert.timeout).to eq(timeout)
  end

  it "has an exec_on_timeout" do
    expect(assert.exec_on_timeout).to eq(exec_on_timeout)
  end

  it "has an exec_on_timeout_ssh_config" do
    expect(assert.exec_on_timeout_ssh_config).to eq(exec_on_timeout_ssh_config)
  end

  describe "default values" do
    let(:assert) do
      Runbook::Statements::Assert.new(cmd)
    end

    it "sets defaults for cmd_ssh_config" do
      expect(assert.cmd_ssh_config).to be_nil
    end

    it "sets defaults for interval" do
      expect(assert.interval).to eq(1)
    end

    it "sets defaults for timeout" do
      expect(assert.timeout).to eq(0)
    end

    it "sets defaults for exec_on_timeout" do
      expect(assert.exec_on_timeout).to be_nil
    end

    it "sets defaults for exec_on_timeout_ssh_config" do
      expect(assert.exec_on_timeout_ssh_config).to be_nil
    end
  end
end
