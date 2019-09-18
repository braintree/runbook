module Runbook::Generators
  class Project < Thor::Group
    include ::Runbook::Generators::Base

    source_root File.dirname(__FILE__)

    def self.description
      "Generate a project for your runbooks"
    end

    def self.long_description
      <<-LONG_DESC
      This generator generates a project for your runbooks. It creates a
      project skeleton to hold your runbooks, runbook extensions, shared
      code, configuration, tests, and dependencies.
      LONG_DESC
    end

    argument :name, desc: "The name of your project, e.x. acme_runbooks"

    class_option :"shared-lib-dir", type: :string,
      desc: "Target directory for shared runbook code"
    class_option :test, type: :string, enum: ["rspec", "minitest"],
      default: "rspec", desc: %Q{Test-suite, "rspec" or "minitest"}

    def init_gem
      bundle_exists = "which bundle 2>&1 1>/dev/null"
      raise "Please ensure bundle is installed" unless system(bundle_exists)

      inside(parent_options[:root]) do
        test = "--test #{options[:test]}"
        continue = (
          run("bundle gem #{_name} #{test} --no-coc --no-mit") ||
          options[:pretend]
        )
        exit 1 unless continue
      end
    end

    def remove_unneeded_files
      dirs = [
        parent_options[:root],
        _name,
      ]

      gemspec_file = File.join(*dirs, "#{_name}.gemspec")
      if File.exist?(gemspec_file)
        @gemspec_file_contents = File.readlines(gemspec_file)
      end
      remove_file(gemspec_file)

      readme = File.join(*dirs, "README.md")
      remove_file(readme)

      gemfile = File.join(*dirs, "Gemfile")
      remove_file(gemfile)

      base_file = File.join(*dirs, "lib", "#{_name}.rb")
      remove_file(base_file)

      version_file_path = [
        "lib",
        _name,
        "version.rb",
      ]
      version_file = File.join(*dirs, *version_file_path)
      remove_file(version_file)
    end

    def shared_lib_dir
      msg = [
        "Where should shared runbook code live?",
        "Use `lib/#{_name}` for runbook-only projects",
        "Use `lib/#{_name}/runbook` for projects used for non-runbook tasks",
        "Shared runbook code path:",
      ]

      if options.has_key?("shared-lib-dir")
        @shared_lib_dir = options["shared-lib-dir"]
      else
        @shared_lib_dir = ask(msg.join("\n"))
      end
    end

    def create_readme
      target = File.join(
        parent_options[:root],
        _name,
        "README.md",
      )

      template("templates/README.md.tt", target)
    end

    def create_gemfile
      target = File.join(
        parent_options[:root],
        _name,
        "Gemfile",
      )

      template("templates/Gemfile.tt", target)

      # Add development dependencies from gemspec
      return unless @gemspec_file_contents
      gems = @gemspec_file_contents.select do |line|
        line =~ /  spec.add_development_dependency/
      end.map do |line|
        line.gsub(/  spec.add_development_dependency/, "gem")
      end.join

      append_to_file(target, "\n#{gems}", verbose: false)
    end

    def create_base_file
      target = File.join(
        parent_options[:root],
        _name,
        "lib",
        "#{_name}.rb",
      )

      template("templates/base_file.rb.tt", target)
    end

    def modify_rakefile
      target = File.join(
        parent_options[:root],
        _name,
        "Rakefile",
      )

      gsub_file(target, /^require "bundler\/gem_tasks"\n/, "", verbose: false)
    end

    def create_ruby_version
      target = File.join(
        parent_options[:root],
        _name,
        ".ruby-version",
      )

      create_file(target, "ruby-#{RUBY_VERSION}\n")
    end

    def create_ruby_gemset
      target = File.join(
        parent_options[:root],
        _name,
        ".ruby-gemset",
      )

      create_file(target, "#{_name}\n")
    end

    def create_runbookfile
      target = File.join(
        parent_options[:root],
        _name,
        "Runbookfile",
      )

      template("templates/Runbookfile.tt", target)
    end

    def create_runbooks_directory
      dirs = [
        parent_options[:root],
        _name,
        "runbooks",
      ]
      target = File.join(*dirs)

      empty_directory(target)
      _keep_dir(target)
    end

    def create_extensions_directory
      dirs = [
        parent_options[:root],
        _name,
        "lib",
        "runbook",
        "extensions",
      ]
      target = File.join(*dirs)

      empty_directory(target)
      _keep_dir(target)
    end

    def create_generators_directory
      dirs = [
        parent_options[:root],
        _name,
        "lib",
        "runbook",
        "generators",
      ]
      target = File.join(*dirs)

      empty_directory(target)
      _keep_dir(target)
    end

    def create_lib_directory
      dirs = [
        parent_options[:root],
        _name,
        @shared_lib_dir,
      ]
      target = File.join(*dirs)

      empty_directory(target)
      _keep_dir(target)
    end

    def update_bin_console
      path = [
        parent_options[:root],
        _name,
        "bin",
        "console",
      ]
      target = File.join(*path)

      old_require = /require "#{_name}"/
      new_require = %Q(require_relative "../lib/#{_name}")
      new_require += "\n\nRunbook::Configuration.load_config"
      gsub_file(target, old_require, new_require, verbose: false)

      old_require = /require "#{_name}"/
      new_require = %Q(require_relative "../lib/#{_name}")
      gsub_file(target, old_require, new_require, verbose: false)
    end

    def remove_bad_test
      path = [
        parent_options[:root],
        _name,
      ]

      case options["test"]
      when "rspec"
        path << "spec"
        path << "#{_name}_spec.rb"
      when "minitest"
        path << "test"
        path << "#{_name}_test.rb"
      end
      target = File.join(*path)

      bad_test = /  .*version.*\n.*\n  end\n\n/m
      gsub_file(target, bad_test, "", verbose: false)
    end

    def runbook_project_overview
      msg = [
        "",
        "Your runbook project was successfully created.",
        "Remember to run `./bin/setup` in your project to install dependencies.",
        "Add runbooks to the `runbooks` directory.",
        "Add shared code to `#{@shared_lib_dir}`.",
        "Execute runbooks using `bundle exec runbook exec <RUNBOOK_PATH>` from your project root.",
        "See the README.md for more details.",
        "\n",
      ]

      say(msg.join("\n"))
    end

    private

    def _name
      @name ||= name.underscore
    end

    def _keep_dir(dir)
      create_file(File.join(dir, ".keep"), verbose: false)
    end
  end
end
