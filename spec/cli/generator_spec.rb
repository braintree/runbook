require "spec_helper"
require 'tmpdir'

RSpec.describe "runbook generate", type: :aruba do
  let(:config_file) { "runbook_config.rb" }
  let(:config_content) do
    <<-CONFIG
    Runbook.configure do |config|
      config.ssh_kit.use_format :dot
    end
    CONFIG
  end
  let(:root) { "generators" }

  before(:each) { write_file(config_file, config_content) }
  before(:each) { create_directory(root) }
  before(:each) { run_command(command) }

  describe "input specification" do
    ["help generate", "generate -h", "generate --help"].each do |help_cmd|
      context help_cmd do
        let(:command) { "runbook #{help_cmd}" }

        it "prints out help instructions" do
          expect(last_command_started).to have_output(/runbook generate generator NAME/)
          expect(last_command_started).to have_output(/-c, \[--config=CONFIG\]/)
          expect(last_command_started).to have_output(/Base options:/)
          expect(last_command_started).to have_output(/\[--root=ROOT\]/)
          expect(last_command_started).to have_output(/Runtime options:/)
        end
      end
    end

    context "when config is passed" do
      let(:config_output) { "This has been evaluated" }
      let(:config_content) do
        <<-CONFIG
          puts "#{config_output}"
        CONFIG
      end

      context "at the top level" do
        let(:command) { "runbook generate --config #{config_file}" }

        it "evaluates the config" do
          expect(last_command_started).to have_output(/#{config_output}/)
        end
      end

      context "at the end" do
        let(:root_opt) { "--root #{root}" }
        let(:config_opt) { "--config #{config_file}" }
        let(:command) { "runbook generate generator gen_name #{root_opt} #{config_opt}" }

        it "evaluates the config" do
          expect(last_command_started).to have_output(/#{config_output}/)
        end
      end
    end

    context "generator generator" do
      ["help generator", "generator -h", "generator --help"].each do |help_cmd|
        context help_cmd do
          let(:command) { "runbook generate #{help_cmd}" }

          it "prints out help instructions" do
            expect(last_command_started).to have_output(/runbook generate generator NAME/)
            expect(last_command_started).to have_output(/-c, \[--config=CONFIG\]/)
            expect(last_command_started).to have_output(/Base options:/)
            expect(last_command_started).to have_output(/\[--root=ROOT\]/)
            expect(last_command_started).to have_output(/Runtime options:/)
            expect(last_command_started).to have_output(/Generate a runbook generator named NAME/)
          end
        end
      end

      context "when name is not passed" do
        let(:command) { "runbook generate generator" }

        it "returns an error" do
          expect(last_command_started).to have_output(/No value provided for required arguments 'name'/)
        end
      end

      context "when name is passed" do
        let(:name) { "my_gen" }
        let(:root_opt) { "--root #{root}" }
        let(:command) { "runbook generate generator #{name} #{root_opt}" }

        it "generates a generator" do
          last_cmd = last_command_started
          expect(last_cmd).to have_output(/create  #{root}\/my_gen/)
          expect(last_cmd).to have_output(/create  #{root}\/my_gen\/templates/)
          expect(last_cmd).to have_output(/create  #{root}\/my_gen\/my_gen.rb/)

          expect(directory?("#{root}/my_gen")).to be_truthy
          expect(directory?("#{root}/my_gen/templates")).to be_truthy
          expect(file?("#{root}/my_gen/my_gen.rb")).to be_truthy

          gen_file = "#{root}/my_gen/my_gen.rb"
          expect(gen_file).to have_file_content(/module Runbook::Generators/)
          expect(gen_file).to have_file_content(/class MyGen < Thor::Group/)
          expect(gen_file).to have_file_content(/include ::Runbook::Generators::Base/)
        end

        context "when --pretend is passed" do
          let(:command) { "runbook generate generator #{name} #{root_opt} --pretend" }

          it "does not create the files" do
            last_cmd = last_command_started
            expect(last_cmd).to have_output(/create  #{root}\/my_gen/)

            expect(file?("#{root}/my_gen")).to be_falsey
          end
        end

        context "when unknown option is passed" do
          let(:command) { "runbook generate generator #{name} #{root_opt} --unknown" }

          it "returns an error" do
            expect(last_command_stopped).to have_output(/Unknown switches "--unknown"/)
          end

          it "returns a non-zero exit code" do
            expect(last_command_stopped.exit_status).to_not eq(0)
          end
        end

        context "when generated generator is invoked" do
          let(:command) { "runbook generate generator #{name} #{root_opt}" }
          let(:runbookfile) { "Runbookfile" }
          let(:runbookfile_content) do
            <<-CONFIG
            require_relative '#{root}/my_gen/my_gen'
            CONFIG
          end

          it "is present in help output" do
            last_cmd = last_command_started
            expect(last_cmd).to have_output(/create  #{root}\/my_gen/)

            write_file(runbookfile, runbookfile_content)
            expect(file?(runbookfile)).to be_truthy

            run_command("runbook generate help")

            expect(last_command_started).to have_output(/runbook generate my_gen \[options\]/)
          end

          it "does not blow up" do
            last_cmd = last_command_started
            expect(last_cmd).to have_output(/create  #{root}\/my_gen/)

            write_file(runbookfile, runbookfile_content)
            expect(file?(runbookfile)).to be_truthy

            run_command("runbook generate my_gen #{root_opt} --help")

            expect(last_command_started).to have_output(/Description:/)
            expect(last_command_started).to have_output(/Generate a my_gen/)
          end
        end
      end
    end

    context "runbook generator" do
      context "when name is not passed" do
        let(:command) { "runbook generate runbook" }

        it "returns an error" do
          expect(last_command_started).to have_output(/No value provided for required arguments 'name'/)
        end
      end

      context "when name is passed" do
        let(:name) { "my_runbook" }
        let(:root_opt) { "--root #{root}" }
        let(:command) { "runbook generate runbook #{name} #{root_opt}" }

        it "generates a runbook" do
          last_cmd = last_command_started
          expect(last_cmd).to have_output(/create  #{root}\/my_runbook.rb/)

          expect(file?("#{root}/my_runbook.rb")).to be_truthy

          gen_file = "#{root}/my_runbook.rb"
          expect(gen_file).to have_file_content(/runbook = Runbook.book "My Runbook" do/)
        end

        context "when generated runbook is executed" do
          let(:command) { "runbook generate runbook #{name} #{root_opt}" }

          it "does not blow up" do
            last_cmd = last_command_started
            expect(last_cmd).to have_output(/create  #{root}\/my_runbook.rb/)

            run_command("runbook exec -a #{root}/my_runbook.rb")

            expect(last_command_started).to have_output(/Executing My Runbook.../)
          end
        end
      end
    end
  end
end
