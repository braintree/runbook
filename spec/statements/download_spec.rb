require "spec_helper"

RSpec.describe Runbook::Statements::Download do
  let(:from) { "/root/my_file.txt" }
  let(:to) { "my_file.txt" }
  let(:options) { {recursive: true} }
  let(:ssh_config) {
    {
      servers: ["server1.prod"],
      path: "/home/bobby_mcgee",
    }
  }
  let(:download) {
    Runbook::Statements::Download.new(
      from,
      to: to,
      ssh_config: ssh_config,
      options: options,
    )
  }

  it "has a from" do
    expect(download.from).to eq(from)
  end

  it "has a to" do
    expect(download.to).to eq(to)
  end

  it "has options" do
    expect(download.options).to eq(options)
  end

  it "has an ssh_config" do
    expect(download.ssh_config).to eq(ssh_config)
  end

  describe "default_values" do
    let(:download) { Runbook::Statements::Download.new(from) }
    it "sets defaults for 'to'" do
      expect(download.to).to be_nil
    end

    it "sets defaults for options" do
      expect(download.options).to eq({})
    end

    it "sets defaults for ssh_config" do
      expect(download.ssh_config).to be_nil
    end
  end
end
