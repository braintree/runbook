require "spec_helper"

RSpec.describe "Runbook Configuration" do
  let(:config) { Runbook::Configuration.new }

  describe "configuration" do
    it "returns a Runbook::Configuration object" do
      expect(Runbook.configuration).to be_a(Runbook::Configuration)
    end

    it "can be assigned a configuration" do
      Runbook.configuration = config
      expect(Runbook.configuration).to eq(config)
    end
  end

  describe "default values" do
    it "sets ssh_kit to SSHKit's config" do
      expect(config.ssh_kit).to be_a(SSHKit::Configuration)
    end
  end

  describe "self.configure" do
    it "allows you to modify the runbook's configuration" do
      old_ssh_kit = Runbook.configuration.ssh_kit
      begin
        Runbook.configure do |config|
          config.ssh_kit = "an ssh kit"
        end

        expect(Runbook.configuration.ssh_kit).to eq("an ssh kit")
      ensure
        Runbook.configuration.ssh_kit = old_ssh_kit
      end
    end
  end

  describe "self.reset_configuration" do
    it "resets the configuration" do
      Runbook.configure do |config|
        config.ssh_kit = "an ssh kit"
      end

      Runbook.reset_configuration
      expect(Runbook.configuration.ssh_kit).to_not eq("an ssh kit")
    end
  end
end
