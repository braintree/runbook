require "spec_helper"

RSpec.describe Runbook::Statements::Assert do
  let(:cmd) { "ps aux | grep [n]ginx" }
  let(:cmd_ssh_config) { {servers: ["server.stg"], parallelization: {}} }
  let(:cmd_raw) { true }
  let(:interval) { 0.5 }
  let(:timeout) { 600 }
  let(:attempts) { 3 }
  let(:timeout_cmd) { %Q{mail -S "Error" me@me.com} }
  let(:timeout_cmd_ssh_config) { {servers: [], parallelization: {}} }
  let(:timeout_cmd_raw) { true }
  let(:abort_statement) do
    Runbook::Statements::Command.new(timeout_cmd, ssh_config: timeout_cmd_ssh_config, raw: timeout_cmd_raw)
  end
  let(:assert) do
    Runbook::Statements::Assert.new(
      cmd,
      cmd_ssh_config: cmd_ssh_config,
      cmd_raw: cmd_raw,
      interval: interval,
      timeout: timeout,
      attempts: attempts,
      abort_statement: abort_statement,
    )
  end

  it "has a cmd" do
    expect(assert.cmd).to eq(cmd)
  end

  it "has a cmd_ssh_config" do
    expect(assert.cmd_ssh_config).to eq(cmd_ssh_config)
  end

  it "has a cmd_raw" do
    expect(assert.cmd_raw).to eq(cmd_raw)
  end

  it "has an interval" do
    expect(assert.interval).to eq(interval)
  end

  it "has a timeout" do
    expect(assert.timeout).to eq(timeout)
  end

  it "has attempts" do
    expect(assert.attempts).to eq(attempts)
  end

  it "has an abort_statement" do
    expect(assert.abort_statement).to eq(abort_statement)
  end

  describe "default values" do
    let(:assert) do
      Runbook::Statements::Assert.new(cmd)
    end

    it "sets defaults for cmd_ssh_config" do
      expect(assert.cmd_ssh_config).to be_nil
    end

    it "sets defaults for cmd_ssh_config" do
      expect(assert.cmd_raw).to be_falsey
    end

    it "sets defaults for interval" do
      expect(assert.interval).to eq(1)
    end

    it "sets defaults for timeout" do
      expect(assert.timeout).to eq(0)
    end

    it "sets defaults for attempts" do
      expect(assert.attempts).to eq(0)
    end

    it "sets defaults for abort_statement" do
      expect(assert.abort_statement).to be_nil
    end
  end
end
