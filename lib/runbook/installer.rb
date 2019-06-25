module Runbook
  class Installer < Thor::Group
    include Thor::Actions

    source_root File.join(
      File.dirname(__FILE__),
      "generators",
      "project",
    )

    add_runtime_options!
    check_unknown_options!

    def create_runbookfile
      template(
        "templates/Runbookfile.tt",
        "Runbookfile",
      )
    end

    def create_runbooks_directory
      target = "runbooks"
      empty_directory(target)
      _keep_dir(target)
    end

    def create_lib_directory
      dirs = [
        "lib",
        "runbook",
      ]
      target = File.join(*dirs)

      empty_directory(target)
      _keep_dir(target)
    end

    def create_extensions_directory
      dirs = [
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
        "lib",
        "runbook",
        "generators",
      ]
      target = File.join(*dirs)

      empty_directory(target)
      _keep_dir(target)
    end

    def runbook_installation_overview
      msg = [
        "",
        "Runbook was successfully installed",
        "Add runbooks to the `runbooks` directory.",
        "Add shared code to `lib/runbook`.",
        "Execute runbooks using `bundle exec runbook exec <RUNBOOK_PATH>`",
        "from your project root.",
        "\n",
      ]

      say(msg.join("\n"))
    end

    private

    def _keep_dir(dir)
      create_file(
        File.join(dir, ".keep"),
        verbose: false,
      )
    end
  end
end
