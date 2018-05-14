## Desired Feature list

Additional statements:

 * [X] `assert`: Run a command with a specified interval until no error is reXurned. Could have timeout and execute behavior on timeout
 * [X] `ask`: Collect user input for future ruby command blocks
 * [X] `ruby_command`: A block of arbitrary ruby code to be executed in the context of the step at runtime
 * [X] `wait`: Sleep for a specified period of time
 * [X] `set`: Set arbitrary data at the step level
 * [X] `capture`: Capture data from a host into a variable
 * [X] `download`: Download a file from a host
 * [X] `upload`: Upload a file to a host

* [X] Allow sections to inherit from sections
* [X] Add way to track depth of a current object in the tree
* [X] Add a way to introspect on your neighbors or place in the tree
* [X] Allow some sort of description statement at the section level
* [X] Allow step-level configuration for the following:
  * parallelization [:parallel, :groups, :sequence], :limit, :wait
  * path
  * user
  * group
  * env
  * umask
* [X] Allow runs and views to be specified via CLI
* [X] Generation plugins
  * Can specify additional generators for output of the runbook (markdown, ssh_kit, etc.)
* [X] Pluggable runbook functionality
  * You can augment the runbook's default keywords with additional keywords to suite your needs and add extra functionality
  * You can for example create a layout declaration that is executed for your runbooks
  * You can hook in to existing handlers to add additional functionality (such as copying all commands to the clipboard)
  * How composable is the DSL? Can you store different pieces in different files and reuse them?
* [X] Runbook lifecycle hooks
  * Can hook into various points of the execution of a runbook to add functionality
  * Example includes adding an option to take notes at each step or logging the run
* [X] raw flag for cmd statements (prevents Cap environment wrapping)
* [X] Prompt at each step option (paranoid mode?)
* [X] various control mechanisms throughout the runbook such as skip, exit, jump to step, etc
* [X] Global configuration (including sshkit config and server configs)
* [X] password sudo
* [X] Add Airbrussh
* [X] Remote commands don't seem to show output?
* [X] Add hierarchical override for ssh_config
* [X] Will need some sort of configuration for the runbook
  * Look for runbookrc in /etc/runbook.conf, Runbookfile, $HOME/.runbookrc, command line arg, runbook file
  * load configurations in this order
  * Overrides or load only a single file? Load overrides
* [] Pass a statement to assert (command, ruby_command, etc.)
* [] Render ssh_config for runs and views
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
* Handles ctrl-c gracefully
* logging solution for alternate output
* Should provide an option to suppress warnings
* Add a tree traversal that detects errors such as ask statements in auto-mode (Noop currently does this)
* Compile-time validations?
* background declaration for ssh_config
* Add support for sudo interaction handler for raw commands
* Docker testing story for more full-stack integration tests
  * Test integration with sshkit
  * Test sshkit-sudo functionality
* ~~cmds can be hashes including ssh_config and raw param~~
* Pattern for conditionally enabling plugins? Conditional plugins should be implemented as separate gems.
  * Have configuration flags toggle the require statements


Possible CLI interface use cases:

```
$ runbook view --output org-mode my_runbook.yml
```

```
$ cat my_runbook.rb | runbook view --input ruby --output yaml --file my_runbook.yml
```

Document:

* [x] Command line interface (without prompts, noop, resume/continue/start at specific step)
  * Reads from standard in, writes to standard out
* Ruby interface
  * You can integrate and execute runbooks from within your existing projects
* [X] Runbooks can be self-contained/runnable files
* [X] Generate markdown
  * Different generators can be used for different types of markdown or generally for different formatting
* [X] Seamlessly integrates with other Ruby libraries (for augmenting functionality)
* [X] Demonstrate how to add aliases for keywords
* [X] Other ways to extend the functionality
* [X] Review README.md
* [] Follow this example for documenting extensions: https://github.com/capistrano/sshkit#custom-formatters

## Open Questions

### Is the set of statements minimalistic?

## Additional Resources

* Review Scaling runbooks: https://knowledge_repo/scaling/runbooks/
* Review Runbook Best Practices
    * https://victorops.com/how-to-build-runbooks?
    * http://holyhandgrenade.org/blog/2011/08/runbooks-are-stupid-and-youre-doing-them-wrong/
    * https://www.ansible.com/blog/migrating-the-runbook-a-journey-from-legacy-to-devops
    * http://www.plutora.com/blog/deployment-runbook
    * https://github.com/SkeltonThatcher/run-book-template/blob/master/run-book-template.md
    * https://www.process.st/create-a-runbook/
    * https://www.rundeck.com/open-source
    * https://automatron.io/
