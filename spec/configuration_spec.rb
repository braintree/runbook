require "spec_helper"
require "tmpdir"

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

  describe "self.load_config" do
    let(:global_config_file) { "runbook.conf" }
    let(:global_const) { "Runbook::Configuration::GlobalConfigFile" }
    let(:global_enable_sudo_prompt) { "false" }
    let(:global_config_content) do
      <<-CONFIG
      Runbook.configure do |config|
        config.enable_sudo_prompt = #{global_enable_sudo_prompt}
      end
      CONFIG
    end

    let(:project_config_file) { "Runbookfile" }
    let(:project_const) { "Runbook::Configuration::ProjectConfigFile" }
    let(:project_enable_sudo_prompt) { "false" }
    let(:project_config_content) do
      <<-CONFIG
      Runbook.configure do |config|
        config.enable_sudo_prompt = #{project_enable_sudo_prompt}
      end
      CONFIG
    end

    let(:user_config_file) { ".runbook.conf" }
    let(:user_const) { "Runbook::Configuration::UserConfigFile" }
    let(:user_enable_sudo_prompt) { "false" }
    let(:user_config_content) do
      <<-CONFIG
      Runbook.configure do |config|
        config.enable_sudo_prompt = #{user_enable_sudo_prompt}
      end
      CONFIG
    end

    context "when GlobalConfigFile is present" do
      it "loads from its global config file" do
        expect(Runbook.configuration.enable_sudo_prompt).to be_truthy
        global_config = Tempfile.new(global_config_file)
        begin
          global_config.write(global_config_content)
          global_config.rewind
          stub_const(global_const, global_config.path)
          Runbook::Configuration.load_config
          expect(Runbook.configuration.enable_sudo_prompt).to be_falsey
        ensure
          global_config.close
          global_config.unlink
        end
      end
    end

    context "when project config file is present in the cwd" do
      let(:global_enable_sudo_prompt) { "true" }
      let(:project_enable_sudo_prompt) { "false" }

      it "overwrites the global config" do
        expect(Runbook.configuration.enable_sudo_prompt).to be_truthy
        global_config = Tempfile.new(global_config_file)
        begin
          global_config.write(global_config_content)
          global_config.rewind
          stub_const(global_const, global_config.path)

          Dir.mktmpdir do |project_dir|
            project_config = Tempfile.new(project_config_file, project_dir)
            begin
              project_config.write(project_config_content)
              project_config.rewind
              project_file = File.basename(project_config.path)
              stub_const(project_const, project_file)
              expect(Dir).to receive(:pwd).and_return(project_dir)

              Runbook::Configuration.load_config
              expect(Runbook.configuration.enable_sudo_prompt).to be_falsey
            ensure
              project_config.close
              project_config.unlink
            end
          end
        ensure
          global_config.close
          global_config.unlink
        end
      end
    end

    context "when project config file is present in parent directory" do
      let(:project_enable_sudo_prompt) { "false" }

      it "sets the config" do
        expect(Runbook.configuration.enable_sudo_prompt).to be_truthy
        Dir.mktmpdir do |project_dir|
          project_config = Tempfile.new(project_config_file, project_dir)
          begin
            project_config.write(project_config_content)
            project_config.rewind
            project_file = File.basename(project_config.path)
            stub_const(project_const, project_file)
            Dir.mktmpdir(nil, project_dir) do |nested_dir|
              expect(Dir).to receive(:pwd).and_return(nested_dir)

              Runbook::Configuration.load_config
              expect(Runbook.configuration.enable_sudo_prompt).to be_falsey
            end
          ensure
            project_config.close
            project_config.unlink
          end
        end
      end
    end

    context "when UserConfigFile is present" do
      let(:user_enable_sudo_prompt) { "false" }

      it "loads from the user config file" do
        expect(Runbook.configuration.enable_sudo_prompt).to be_truthy
        user_config = Tempfile.new(user_config_file)
        begin
          user_config.write(user_config_content)
          user_config.rewind
          user_dir = File.dirname(user_config.path)
          user_file = File.basename(user_config.path)
          stub_const(user_const, user_file)
          expect(ENV).to receive(:[]).with("HOME").and_return(user_dir)
          Runbook::Configuration.load_config
          expect(Runbook.configuration.enable_sudo_prompt).to be_falsey
        ensure
          user_config.close
          user_config.unlink
        end
      end
    end
  end
end
