## Desired feature list
* [X] Revise README.md
* [X] Create a generator for a runbook? Allow for custom generators?
  * [ ] Generate runbook templates
  * [ ] Generate runbook projects with Runbookfile, Gemfile, etc.
  * [ ] Generate plugins
* [ ] capistrano-runbook gem that integrates runbook into capistrano tasks
* [ ] Add Appraisal to test against multiple versions of Ruby
* [ ] Update output to be more log friendly, including timestamps for operations
* [ ] Allow for preventing echo when prompting for input
* [ ] Add an ability for skipping mutation commands that will have an affect on the system
* [ ] Add a revert section that does not get executed, but can be executed by passing a revert flag
* [ ] Specify version in runbook to allow for supporting backwards incompatible runbook DSL format changes
* [ ] Add support for sudo interaction handler for raw commands
* [ ] Replace Thor with a solution that is more easily extendable (adding new flags, etc.)
* [ ] Add goto statements for repeating steps (functionality exists in paranoid mode)
* [ ] Add test statement
* [ ] Add ruby_assert statement
* [ ] Feedback on completion of tmux commands (when they complete, return values, outputs)
* [ ] Add shorter aliases for tmux layout keys
* [ ] Add host aliases for ssh_config setters
* [ ] Allow for step dependencies that get executed before the step
* [ ] Add periodic flush for sshkit output
* [ ] Update assert attribute nomenclature (timeout_statement)
* [ ] Update ssh_kit to count commands separately between steps
* [ ] Create a plugin generator
* [ ] Create generator for a new run (sshkit, etc.)
* [ ] Create generator for a new view (markdown, yaml, html, etc.)
* [ ] Add rake tasks to generators for viewing and executing runbooks
* [ ] Add a way to execute a series of commands in groups
* [ ] Docker testing story for more full-stack integration tests
  * [ ] Test integration with sshkit
  * [ ] Test sshkit-sudo functionality
* [ ] Logging solution for alternate output
* [ ] Pattern for conditionally enabling plugins? Conditional plugins should be implemented as separate gems.
  * [ ] Requiring a plugin is the same as enabling it
  * [ ] Configuration can be added to toggle aspects of the plugin
* [ ] Add a setup step that always executes even if start_at is defined
* [ ] Yaml specification format (subset of Ruby)
  * [ ] Will not contain as much flexibility as Ruby format
  * [ ] Can convert from Ruby format to yaml (depending on compatibility) and yaml to Ruby
* [ ] Guard for view updates (How to handle arguments?)
* [ ] Be able to serve up markdown docs (web server) for easy viewing
* [ ] Add interactive executable for all runbooks in a project
* [ ] Could provide a rake task for compiling and nooping runbooks?
* [ ] Can specify input-format, output-format, input (file), and output (file)
