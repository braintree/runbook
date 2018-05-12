require "spec_helper"

RSpec.describe "Runbook Configuration" do
  let(:config) { Runbook::Configuration.new }

  before(:all) { Runbook.reset_configuration }
  after(:each) { Runbook.reset_configuration }

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

    it "sets ssh_kit.output to an Airbrussh::Formatter" do
      expect(config.ssh_kit.output).to be_a(Airbrussh::Formatter)
    end

    it "sets enable_sudo_prompt to true" do
      expect(config.enable_sudo_prompt).to eq(true)
    end

    it "sets use_same_sudo_password to true" do
      expect(config.use_same_sudo_password).to eq(true)
    end
  end

  describe "config.use_same_sudo_password=" do
    let (:host) { SSHKit::Host.new("user@host") }

    context "when set to true" do
      it "sets SSHKit::Sudo::InteractionHandler.password_cache_key to 0" do
        config.use_same_sudo_password = true
        expect(
          SSHKit::Sudo::InteractionHandler.new.password_cache_key(host)
        ).to eq("0")
      end
    end

    context "when set to false" do
      it "sets SSHKit::Sudo::InteractionHandler.password_cache_key to the unique user and host" do
        config.use_same_sudo_password = false
        expect(
          SSHKit::Sudo::InteractionHandler.new.password_cache_key(host)
        ).to eq("user@host")
      end
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
