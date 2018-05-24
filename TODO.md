## Desired Feature list

* [X] Add version argument to cli
* [X] Allow ask statement to take a default
* [] Add support for sudo interaction handler for raw commands
* [] Render ssh_config for runs
* [] Add Appraisal
* [] Add a revert section that does not get executed, but can be executed by passing a revert flag
* Could provide a rake task for compiling and nooping runbooks?
* Create a generator for a runbook? Allow for custom generators?
  * Generate runbook projects with Runbookfile, Gemfile, etc.
  * Generate plugins
  * Generate runbooks templates
* Guard for view updates (How to handle arguments?)
* Be able to serve up markdown docs (web server) for easy viewing
* Can specify input-format, output-format, input (file), and output (file)
* Yaml specification format (subset of Ruby)
  * Will not contain as much flexibility as Ruby format
  * Can convert from Ruby format to yaml (depending on compatibility) and yaml to Ruby
* logging solution for alternate output
* background declaration for ssh_config
* Docker testing story for more full-stack integration tests
  * Test integration with sshkit
  * Test sshkit-sudo functionality
* Pattern for conditionally enabling plugins? Conditional plugins should be implemented as separate gems.
  * Have configuration flags toggle the require statements
