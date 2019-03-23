## Desired Feature list

* [X] Allow statements to take blocks to specify their arguments
* [X] Add sanity checks for tmux support
* [X] Add helper for registering runbooks
* [X] Don't prompt for steps without titles
* [] Create a generator for a runbook? Allow for custom generators?
  * Generate runbook templates
  * Generate runbook projects with Runbookfile, Gemfile, etc.
  * Generate plugins
* [] Revise README.md
* [] Add Appraisal to test against multiple versions of Ruby
* [] Update output to be more log friendly, including timestamps for operations
* [] Allow for preventing echo when prompting for input
* [] Render ssh_config for runs
* [] Add an ability for skipping mutation commands that will have an affect on the system
* [] Add a revert section that does not get executed, but can be executed by passing a revert flag
* [] Specify version in runbook to allow for supporting backwards incompatible runbook DSL format changes
* [] Add support for sudo interaction handler for raw commands
* [] Replace Thor with a solution that is more easily extendable (adding new flags, etc.)
* [] Add goto statements for repeating steps (functionality exists in paranoid mode)
* [] Add test statement
* [] Feedback on completion of tmux commands (when they complete, return values, outputs)
* Docker testing story for more full-stack integration tests
  * Test integration with sshkit
  * Test sshkit-sudo functionality
* logging solution for alternate output
* Pattern for conditionally enabling plugins? Conditional plugins should be implemented as separate gems.
  * Requiring a plugin is the same as enabling it
  * Configuration can be added to toggle aspects of the plugin
* Yaml specification format (subset of Ruby)
  * Will not contain as much flexibility as Ruby format
  * Can convert from Ruby format to yaml (depending on compatibility) and yaml to Ruby
* Guard for view updates (How to handle arguments?)
* Be able to serve up markdown docs (web server) for easy viewing
* Could provide a rake task for compiling and nooping runbooks?
* Can specify input-format, output-format, input (file), and output (file)
* background declaration for ssh_config <<- No longer supported by sshkit
