## Desired Feature list

* [X] Allow statements to take blocks to specify their arguments
* [X] Add sanity checks for tmux support
* [] Add Appraisal
* [] Update output to be more log friendly, including timestamps for operations
* [] Override ssh_config at section, step levels
* [] Render ssh_config for runs
* [] Add an ability for skipping mutation commands that will have an affect on the system
* [] Add a revert section that does not get executed, but can be executed by passing a revert flag
* [] Allow for preventing echo when prompting for input
* [] Specify version in runbook to allow for supporting backwards incompatible runbook DSL format changes
* [] Add support for sudo interaction handler for raw commands
* [] Replace Thor with a solution that is more easily extensible (adding new flags, etc.)
* Could provide a rake task for compiling and nooping runbooks?
* Create a generator for a runbook? Allow for custom generators?
  * Generate runbook projects with Runbookfile, Gemfile, etc.
  * Generate plugins
  * Generate runbooks templates
* logging solution for alternate output
* Guard for view updates (How to handle arguments?)
* Be able to serve up markdown docs (web server) for easy viewing
* Can specify input-format, output-format, input (file), and output (file)
* Yaml specification format (subset of Ruby)
  * Will not contain as much flexibility as Ruby format
  * Can convert from Ruby format to yaml (depending on compatibility) and yaml to Ruby
* background declaration for ssh_config
* Docker testing story for more full-stack integration tests
  * Test integration with sshkit
  * Test sshkit-sudo functionality
* Pattern for conditionally enabling plugins? Conditional plugins should be implemented as separate gems.
  * Have configuration flags toggle the require statements
