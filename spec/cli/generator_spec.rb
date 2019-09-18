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

    context "statement generator" do
      context "when name is not passed" do
        let(:command) { "runbook generate statement" }

        it "returns an error" do
          expect(last_command_started).to have_output(/No value provided for required arguments 'name'/)
        end
      end

      context "when name is passed" do
        let(:name) { "my_statement" }
        let(:root_opt) { "--root #{root}" }
        let(:command) { "runbook generate statement #{name} #{root_opt}" }

        it "generates a statement" do
          last_cmd = last_command_started
          expect(last_cmd).to have_output(/create  #{root}\/my_statement.rb/)

          expect(file?("#{root}/my_statement.rb")).to be_truthy

          gen_file = "#{root}/my_statement.rb"
          expect(gen_file).to have_file_content(/class MyStatement < Runbook::Statement/)
        end

        context "exercising the generated statement" do
          let(:runbook_file) { "my_runbook.rb" }
          let(:content) do
            <<-RUNBOOK
            require_relative "#{root}/my_statement"

            runbook = Runbook.book "My Runbook" do
              section "Section" do
                step { my_statement "ice", "cream" }
              end
            end
            RUNBOOK
          end

          before(:each) { write_file(runbook_file, content) }

          context "when generated statement is viewed" do
            let(:command) { "runbook generate statement #{name} #{root_opt}" }

            it "exercises the statement" do
              last_cmd = last_command_started
              expect(last_cmd).to have_output(/create  #{root}\/my_statement.rb/)

              run_command("sed -i 's/MyProject/Runbook/' #{root}/my_statement.rb")
              run_command("runbook view my_runbook.rb")

              expect(last_command_started).to have_output(/icecream/)
            end
          end

          context "when generated statement is executed" do
            let(:command) { "runbook generate statement #{name} #{root_opt}" }

            it "exercises the statement" do
              last_cmd = last_command_started
              expect(last_cmd).to have_output(/create  #{root}\/my_statement.rb/)

              exec_sentinel = "# and the current metadata for this step of the execution"
              exec_statement = "metadata[:toolbox].output(object.attr1 + object.attr2)"
              run_command("sed -i 's/MyProject/Runbook/' #{root}/my_statement.rb")
              run_command("sed -i 's/#{exec_sentinel}/#{exec_statement}/' #{root}/my_statement.rb")
              run_command("runbook exec -a my_runbook.rb")

              expect(last_command_started).to have_output(/icecream/)
            end
          end
        end
      end
    end

    context "dsl_extension generator" do
      context "when name is not passed" do
        let(:command) { "runbook generate dsl_extension" }

        it "returns an error" do
          expect(last_command_started).to have_output(/No value provided for required arguments 'name'/)
        end
      end

      context "when name is passed" do
        let(:name) { "rollback_section" }
        let(:root_opt) { "--root #{root}" }
        let(:command) { "runbook generate dsl_extension #{name} #{root_opt}" }

        it "generates a dsl_extension" do
          last_cmd = last_command_started
          expect(last_cmd).to have_output(/create  #{root}\/rollback_section.rb/)

          expect(file?("#{root}/rollback_section.rb")).to be_truthy

          gen_file = "#{root}/rollback_section.rb"
          expect(gen_file).to have_file_content(/module RollbackSection/)
        end

        context "exercising the generated dsl_extension" do
          let(:runbook_file) { "my_runbook.rb" }
          let(:content) do
            <<-RUNBOOK
            require_relative "#{root}/rollback_section"

            runbook = Runbook.book "My Runbook" do
              rollback_section("Rollback Section") {}
            end
            RUNBOOK
          end

          before(:each) { write_file(runbook_file, content) }

          context "when generated dsl_extension is viewed" do
            let(:command) { "runbook generate dsl_extension #{name} #{root_opt}" }

            it "exercises the dsl_extension" do
              last_cmd = last_command_started
              expect(last_cmd).to have_output(/create  #{root}\/rollback_section.rb/)

              run_command("sed -i 's/MyProject/Runbook/' #{root}/rollback_section.rb")
              exec_sentinel = "module DSL"
              exec_statement = "module DSL; def rollback_section(title, \\&block); section(title, \\&block); end"
              run_command("sed -i 's/#{exec_sentinel}/#{exec_statement}/' #{root}/rollback_section.rb")
              exec_sentinel = "# Runbook::Entities::Book::DSL"
              exec_statement = "Runbook::Entities::Book::DSL"
              run_command("sed -i 's/#{exec_sentinel}/#{exec_statement}/' #{root}/rollback_section.rb")
              run_command("runbook view my_runbook.rb")

              expect(last_command_started).to have_output(/Rollback Section/)
            end
          end

          context "when generated dsl_extension is executed" do
            let(:command) { "runbook generate dsl_extension #{name} #{root_opt}" }

            it "exercises the dsl_extension" do
              last_cmd = last_command_started
              expect(last_cmd).to have_output(/create  #{root}\/rollback_section.rb/)

              run_command("sed -i 's/MyProject/Runbook/' #{root}/rollback_section.rb")
              exec_sentinel = "module DSL"
              exec_statement = "module DSL; def rollback_section(title, \\&block); section(title, \\&block); end"
              run_command("sed -i 's/#{exec_sentinel}/#{exec_statement}/' #{root}/rollback_section.rb")
              exec_sentinel = "# Runbook::Entities::Book::DSL"
              exec_statement = "Runbook::Entities::Book::DSL"
              run_command("sed -i 's/#{exec_sentinel}/#{exec_statement}/' #{root}/rollback_section.rb")
              run_command("runbook exec my_runbook.rb")

              expect(last_command_started).to have_output(/1. Rollback Section/)
            end
          end
        end
      end
    end

    context "project generator" do
      context "when name is not passed" do
        let(:command) { "runbook generate project" }

        it "returns an error" do
          expect(last_command_started).to have_output(/No value provided for required arguments 'name'/)
        end
      end

      context "when name is passed" do
        let(:name) { "my_runbooks" }
        let(:root) { "." }
        let(:root_opt) { "--root #{root}" }
        let(:test) { "rspec" }
        let(:test_opt) { "--test #{test}" }
        let(:shared_lib_dir) { "lib/my_runbooks" }
        let(:shared_lib_dir_opt) { "--shared-lib-dir #{shared_lib_dir}" }
        let(:command) { "runbook generate project #{name} #{test_opt} #{shared_lib_dir_opt} #{root_opt}" }

        it "generates a project" do
          last_cmd = last_command_started
          bundle_gem_output = %Q{run  bundle gem #{name} --test #{test} --no-coc --no-mit from "."}
          gem_successfully_created = %Q{Gem 'my_runbooks' was successfully created.}
          project_generation_output = [
            "remove  my_runbooks/my_runbooks.gemspec",
            "remove  my_runbooks/README.md",
            "remove  my_runbooks/Gemfile",
            "remove  my_runbooks/lib/my_runbooks.rb",
            "remove  my_runbooks/lib/my_runbooks/version.rb",
            "create  my_runbooks/README.md",
            "create  my_runbooks/Gemfile",
            "create  my_runbooks/lib/my_runbooks.rb",
            "create  my_runbooks/.ruby-version",
            "create  my_runbooks/.ruby-gemset",
            "create  my_runbooks/Runbookfile",
            "create  my_runbooks/runbooks",
            "create  my_runbooks/lib/runbook/extensions",
            "create  my_runbooks/lib/runbook/generators",
            " exist  my_runbooks/lib/my_runbooks",
            "Your runbook project was successfully created.",
            "Remember to run `./bin/setup` in your project to install dependencies.",
            "Add runbooks to the `runbooks` directory.",
            "Add shared code to `lib/my_runbooks`.",
            "Execute runbooks using `bundle exec runbook exec <RUNBOOK_PATH>` from your project root.",
            "See the README.md for more details.",
          ]

          expect(last_cmd).to have_output(/#{bundle_gem_output}/)
          expect(last_cmd).to have_output(/#{gem_successfully_created}/)
          project_generation_output.each do |output|
            expect(last_cmd).to have_output(/#{output}/)
          end

          gemfile = "#{root}/#{name}/Gemfile"
          expect(file?(gemfile)).to be_truthy
          expect(gemfile).to have_file_content(/gem "bundler"/)
          expect(gemfile).to have_file_content(/gem "rake"/)
          expect(gemfile).to have_file_content(/gem "rspec"/)
        end
      end

      context "when -p is passed" do
        let(:name) { "my_runbooks" }
        let(:root) { "." }
        let(:root_opt) { "--root #{root}" }
        let(:test) { "rspec" }
        let(:test_opt) { "--test #{test}" }
        let(:shared_lib_dir) { "lib/my_runbooks" }
        let(:shared_lib_dir_opt) { "--shared-lib-dir #{shared_lib_dir}" }
        let(:command) { "runbook generate project #{name} #{test_opt} #{shared_lib_dir_opt} #{root_opt} -p" }

        it "does not generate a project" do
          last_cmd = last_command_started
          bundle_gem_output = %Q{run  bundle gem #{name} --test #{test} --no-coc --no-mit from "."}
          gem_successfully_created = %Q{Gem 'my_runbooks' was successfully created.}
          project_generation_output = [
            "remove  my_runbooks/my_runbooks.gemspec",
            "remove  my_runbooks/README.md",
            "remove  my_runbooks/Gemfile",
            "remove  my_runbooks/lib/my_runbooks.rb",
            "remove  my_runbooks/lib/my_runbooks/version.rb",
            "create  my_runbooks/README.md",
            "create  my_runbooks/Gemfile",
            "create  my_runbooks/lib/my_runbooks.rb",
            "create  my_runbooks/.ruby-version",
            "create  my_runbooks/.ruby-gemset",
            "create  my_runbooks/Runbookfile",
            "create  my_runbooks/runbooks",
            "create  my_runbooks/lib/runbook/extensions",
            "create  my_runbooks/lib/runbook/generators",
            "create  my_runbooks/lib/my_runbooks",
            "Your runbook project was successfully created.",
            "Remember to run `./bin/setup` in your project to install dependencies.",
            "Add runbooks to the `runbooks` directory.",
            "Add shared code to `lib/my_runbooks`.",
            "Execute runbooks using `bundle exec runbook exec <RUNBOOK_PATH>` from your project root.",
            "See the README.md for more details.",
          ]

          expect(last_cmd).to have_output(/#{bundle_gem_output}/)
          expect(last_cmd).to_not have_output(/#{gem_successfully_created}/)
          project_generation_output.each do |output|
            expect(last_cmd).to have_output(/#{output}/)
          end

          gemfile = "#{root}/#{name}/Gemfile"
          expect(file?(gemfile)).to be_falsey
        end
      end

      context "when an invalid name is passed" do
        let(:name) { "7l" }
        let(:root) { "." }
        let(:root_opt) { "--root #{root}" }
        let(:test) { "rspec" }
        let(:test_opt) { "--test #{test}" }
        let(:shared_lib_dir) { "lib/my_runbooks" }
        let(:shared_lib_dir_opt) { "--shared-lib-dir #{shared_lib_dir}" }
        let(:command) { "runbook generate project #{name} #{test_opt} #{shared_lib_dir_opt} #{root_opt}" }

        it "does not generate a project" do
          last_cmd = last_command_started
          bundle_gem_output = %Q{run  bundle gem #{name} --test #{test} --no-coc --no-mit from "."}
          invalid_gem_name = %Q{Invalid gem name 7l Please give a name which does not start with numbers.}
          project_generation_output = [
            "remove  my_runbooks/my_runbooks.gemspec",
            "remove  my_runbooks/README.md",
            "remove  my_runbooks/Gemfile",
            "remove  my_runbooks/lib/my_runbooks.rb",
            "remove  my_runbooks/lib/my_runbooks/version.rb",
            "create  my_runbooks/README.md",
            "create  my_runbooks/Gemfile",
            "create  my_runbooks/lib/my_runbooks.rb",
            "create  my_runbooks/.ruby-version",
            "create  my_runbooks/.ruby-gemset",
            "create  my_runbooks/Runbookfile",
            "create  my_runbooks/runbooks",
            "create  my_runbooks/lib/runbook/extensions",
            "create  my_runbooks/lib/runbook/generators",
            " exist  my_runbooks/lib/my_runbooks",
            "Your runbook project was successfully created.",
            "Remember to run `./bin/setup` in your project to install dependencies.",
            "Add runbooks to the `runbooks` directory.",
            "Add shared code to `lib/my_runbooks`.",
            "Execute runbooks using `bundle exec runbook exec <RUNBOOK_PATH>` from your project root.",
            "See the README.md for more details.",
          ]

          expect(last_cmd).to have_output(/#{bundle_gem_output}/)
          expect(last_cmd).to have_output(/#{invalid_gem_name}/)
          project_generation_output.each do |output|
            expect(last_cmd).to_not have_output(/#{output}/)
          end

          gemfile = "#{root}/#{name}/Gemfile"
          expect(file?(gemfile)).to be_falsey
          expect(gemfile).to_not have_file_content(/gem "bundler"/)
          expect(gemfile).to_not have_file_content(/gem "rake"/)
          expect(gemfile).to_not have_file_content(/gem "rspec"/)
          expect(last_command_stopped.exit_status).to_not eq(0)
        end
      end
    end
  end
end
