# Runbook TODO

## Description

This document covers a list of ideas for Runbook improvements. Ideas vary wildly in terms of difficulty, desireability, and conceptual completeness. Each idea has a difficulty, desireability, and conceptual completeness rating from 1 to 3. These ideas are roughly ordered in terms of priority. 

Ratings are as follows:

Difficulty:

* 1: Easy
* 2: Medium
* 3: Hard

Desireability:

* 1: Must have
* 2: Nice to have
* 3: May be nice to have

Conceptual Completeness:

* 1: I know exactly how to implement this
* 2: I have some idea about how to implement this
* 3: I have no ideas about how to implement this

## Other Considerations

Runbook is intended to be a light-weight, minimalistic library. This means every feature must be weighed against the usability of work-arounds in order to determine if a feature is worth including in Runbook. Sometimes features are easy and straightforward to implement but not enough demand has been demonstrated to justify including the feature into Runbook.

## Features Outline

* [Sudo Raw Command Support](#sudo-raw-command-support): Add support for sudo interaction handler for raw commands
* [Always-executed Setup Section](#always-executed-setup-section): Add support for a section that is never skipped
* [Shortened Tmux Layout Keys](#shortened-tmux-layout-keys): Make tmux layout keys easier
* [Add Host Aliases for SSH Config](#add-host-aliases-for-ssh-config): Use `host` and `hosts` instead of `server` and `servers`
* [Capistrano-runbook Gem](#capistrano-runbook-gem): A gem for integrating runbook directly into capistrano
* [Blocking Tmux Commands](#blocking-tmux-commands): Don't continue execution until the tmux_command completes
* [Runbook Logger](#runbook-logger): A logger for Runbook
* [Mutation Command Skipping](#mutation-command-skipping): Allow skipping mutation commands
* [Revert Section](#revert-section): A section that can be triggered which will revert the changes of the runbook
* [Runbook Versioning](#runbook-versioning): Specify a version in a runbook to allow for supporting backwards incompatible runbook DSL format changes
* [Replace Thor CLI](#replace-thor-cli): Replace Thor for Runbook's CLI with something that can be more easily extended and customized
* [Goto Statement](#goto-statement): A statement for jumping to a specific step
* [Test Statement](#test-statement): A statement for executing a remote command and conditioning on its success
* [RubyAssert Statement](#rubyassert-statement): A statement analogous to assert, but executing a block instead of a command
* [Docker Testing](#docker-testing): Add tests that execute against docker containers
* [Tmux Command Results](#tmux-command-results): Capture outputs and status codes for tmux commands
* [Step Dependencies](#step-dependencies): Like rake, allow a step to invoke another step if it has not been executed
* [Update Command Counts](#update-command-counts): Use step titles for counting commands executed in a step
* [Create Plugin Generator](#create-plugin-generator): A generator for creating boilerplate for a new Runbook plugin
* [Create Run Generator](#create-run-generator): A generator for creating boilerplate for a new run such as sshkit
* [Create View Generator](#create-view-generator): A generator for creating boilerplate for a new view such as markdown, yaml, html
* [Outline View Option](#outline-view-option): A command-line option to only execute entity nodes
* [Guard Runbook](#guard-runbook): Automatically update Runbook views when a runbook is saved
* [Rake Task Interface](#rake-task-interface): Execute and view runbooks with rake tasks
* [Multiple Commands In Groups](#multiple-commands-in-groups): Execute multiple sshkit commands for a group of servers before moving on to a new group of servers
* [Yaml Specification](#yaml-specification): Define your runbook using yaml instead of Ruby
* [Runbook Web Server](#runbook-web-server): Automatically serve up Runbook views via the web
* [Interactive Runbook Launcher](#interactive-runbook-launcher): A CLI launcher to review and execute runbooks

### Feature Details

#### Sudo Raw Command Support

**Difficulty: 1**, **Desireability: 1**, **Conceptual Completeness: 1**

Runbook supports a password prompt when executing commands using sudo. The typical way to execute sudo commands is to specify the `user` setter. This will do three things. It will (1) set the interaction handler when performing the initial [sudo check](https://github.com/braintree/runbook/blob/54e90f2a9c93704857bc31b0e03769b6e959d879/lib/hacks/ssh_kit.rb#L40-L49) and the pty for the execution of the command. It will (2) wrap the command to be executed with [a call to sudo](https://github.com/braintree/runbook#command-quoting). And it will (3) set the [interaction handler for commands](https://github.com/braintree/runbook/blob/54e90f2a9c93704857bc31b0e03769b6e959d879/lib/runbook/helpers/ssh_kit_helper.rb#L11-L13) that are executing which are wrapped in sudo.

Raw commands remove all the [command wrapping](https://github.com/braintree/runbook/commit/075d95c214c44db2c2803c211fbd40e1fbc89ae9#diff-a4bf760ce531af31e88293aecd750138https://github.braintreeps.com/braintree/runbook#command-quoting) that is performed when specifying commands. This is nice when you want to avoid the helper functionality when it complicates or obfuscates the command you are trying to execute (for example trying to escape nested quotes).

when raw is specified, number (!) above is not executed. Thus pty is not set to true. (2) can be assumed to manually be performed by the user (they will have to type their own sudo command). (3) Is currently toggled by the user setter and the `enable_sudo_prompt` config.

An ideal solution for this would allow the user to set pty true for the command to be executed via ssh_config. Additionally, it would be beneficial to set their own interaction handler. It seems safe to assume that if a user specifies that a command be executed with a pty, then we can set the sudo interaction handler by default if `enable_sudo_prompt` is set, but still allow for the interaction_handler to be overridden.

#### Always-executed Setup Section

**Difficulty: 2**, **Desireability: 1**, **Conceptual Completeness: 2**

It is often a best practice to provide a setup section at the beginning of your runbook which gathers all required info for the runbook so the rest of the runbook can execute with minimal interruption. Under certain circumstances it can be ideal to ensure this section is always run, so that if you want to jump to the middle of a runbook, you can have confidence that any necessary initial configuration is executed.

This can additionally be used if you want to dynamically define your runbook based on some initial input, then you can ensure that this is executed and you can step to the middle of a runbook, but know that the step has been defined by the initial setup. This, however, would not aid in generating a proper view for the runbook.

#### Shortened Tmux Layout Keys

**Difficulty: 1**, **Desireability: 1**, **Conceptual Completeness: 1**

`directory` should become `path` because it is shorter and consistent with the DSL. `runbook_pane` should become `runbook` because it is shorter and just as intuitive. Usage of old values should be marked as deprecated.

#### Add Host Aliases for SSH Config

**Difficulty: 1**, **Desireability: 1**, **Conceptual Completeness: 1**

`server` should become `host` because it is shorter. `servers` should become `hosts` because it is shorter and just as intuitive. Usage of old values should be marked as deprecated.

#### Capistrano-runbook Gem

**Difficulty: 2**, **Desireability: 1**, **Conceptual Completeness: 2**

A number of Ruby and non-Ruby projects use capistrano for deployments and other one-off tasks. Often times an application or organization's server inventory/manifest lives within capistrano. Creating a `capistrano-runbook` gem would (a) Allow you to access server lists programmatically within your runbooks based on role and (b) invoke capistrano tasks within the same Ruby process. 

The implementation for this would be pretty straightforward. It would provide an alternative interface for invoking runbooks (as opposed to invoking via the CLI).

Helpful links:

* https://github.com/braintree/runbook/blob/0c0a028dffe88f0bb45ab2afcffe202ae3baa58b/lib/runbook/cli.rb#L52-L66
* https://github.com/braintree/runbook/blob/0c0a028dffe88f0bb45ab2afcffe202ae3baa58b/lib/runbook/cli.rb#L22-L28
* https://github.com/braintree/runbook/blob/master/README.md#from-within-your-project

#### Blocking Tmux Commands

**Difficulty: 2**, **Desireability: 1**, **Conceptual Completeness: 2**

Right now tmux commands are started and then immediately return control to the runbook. It would be ideal if a flag could be passed to not return control to the runbook until the tmux command has completed. Additionally, it may be nice to have a block command that waits for one of multiple tmux commands to finish executing. One potential implementation for this is to use `ps`. Another may be to use the `proc` file system. I am not aware of anything built into tmux for this purpose.

#### Runbook Logger

**Difficulty: 1**, **Desireability: 1**, **Conceptual Completeness: 2**

Include a dedicated logger for Runbook that is incorporated into the execution. This can be off by default, but enabled by setting a log file. Additionally, a log-level can be set. Log output should include what is being executed, and what the result is. The log should be compatible with sshkit's log output. Additionally, this should be implemented in a way that all normal output is suppressed and log output is written to stdout. It would be nice if adding logging did not require additional code for each entity and statement execution.

#### Mutation Command Skipping

**Difficulty: ?**, **Desireability: 2**, **Conceptual Completeness: 3**

It would be nice to be able to skip commands that you know will have an effect on your system. The main use case for this is testing. You can test your runbook more thoroughly and have confidence that it will not make changes to your system. It would be difficult if not impossible to determine what commands will have a mutable affect, so this will likely need to be user-determined.

One way to accomplish this is through a tags implementation where entities and statements have a set of tags, and their behavior is controlled based on these tags. I have implemented a spike of adding tags to entities. One complication of skipping mutation commands is that it is not easy to determine if future commands rely on that command executing. This could reduce the overall benefit of flagging and skipping mutation commands. The skipping logic could be implemented using Runbook's hooks feature.

Skipping mutation commands for the sake of testing may also be accomplished through the use of mocks. This could a testing library or perhapsa mocking solution built out for Runbook. Implementing a mocking pattern could resolve the downstream dependency issue of skipping mutation commands. A mocking solution could also be implemented using Runbook hooks.

The mutation command skipping behavior could be controlled via an environment variable. It may be controlled via config or other flag, but this feels too specific to be included in the more general config or run options.  

#### Revert Section

**Difficulty: ?**, **Desireability: 3**, **Conceptual Completeness: 2**

It is a best practice to have a plan for reverting any system changes you make. It would be nice to have a way to include this revert plan in with your runbook and simply trigger its execution with a flag. The revert plan may not be straight-forward if the rollout plan did not run to completion, so revert plans may need to assume this to be the case. Also, it does not appear possible to infer what rollback steps would be based on the initial runbook.

This functionality could be achieved by adding a new revert entity which responds to a revert flag passed by the user (environment variable, command line config, runner/viewer option). Instead of a separate entity, this could be accomplished with a tagging solution, where a section has a revert tag that designates it should be skipped unless the revert flag is present (and vis-versa for non-revert sections). The skipping logic could be implemented using Runbook hooks.

A workaround for this is to simply have a separate revert runbook to execute in the event a rollbock is needed.

#### Runbook Versioning

**Difficulty: 1**, **Desireability: 3**, **Conceptual Completeness: 1**

Right now if the API for the Runbook DSL changes in a backwards incompatible way, the runbook will break when being executed with the new version of Runbook. If we add a version declaration for the runbook, then we can conditionally execute the backwards incompatibile code based on the version. 

An alternative to including a version declaration would be to only change backwards incompatibilities between major versions of Runbook, and require that users of the new version update all their runbooks to be compatible with the new version. Including a version declaration may make this more explicit and easy to know which versions are an are not compatible. As the version declaration is meant to indicate a DSL backwards incompatibility, this should be detectable by simply compiling the runbooks using the view functionality, or another side-effectless compilation to determine when things break. 

A version flag can always be added at a later date, and Runbooks without the flag can be considered to be the older version. This could be set to be required for new Runbooks.

#### Replace Thor CLI

**Difficulty: 3**, **Desireability: 2**, **Conceptual Completeness: 2**

It would be nice if Runbook's CLI interface could be customized via the use of plugins. Thor commands and options are specified by executing methods in a specific order in a class, so it is not easily extensible if a plugin wants to customize the CLI. One possible solution is to replace Thor with another CLI solution such as Ruby's build int option parser or GLI. I am not sure what other good solutions out there exist.

Another solution could be to extend Thor in a way that additional arguments can "fall through" or perhaps accept variable arguments that get set on runbook config which can be used to modify execution behavior. This solution may be better because it sets a clear boundary between core runbook and plugins.

#### Goto Statement

**Difficulty: 1**, **Desireability: 2**, **Conceptual Completeness: 1**

This statement would provide the same behavior as the jump option at the step menu, allowing you to go to a certain step. Jump may be a better keyword than goto. An existing workaround is to use `ruby_command` and set `start_at` in the metadata. This behavior could be used for repeating steps until a certain criteria is met.

#### Test Statement

**Difficulty: 1**, **Desireability: 2**, **Conceptual Completeness: 1**

This statement would take a command, execute it using SSHKit's test command, and then yield its return value as a boolean that can be conditioned on within a block. The block should have the same context as a ruby_command. A workaround is to use capture combined with echoing `$?` or similar to capture the return value of your command and then condition on the value returned.

#### RubyAssert Statement

**Difficulty: 1**, **Desireability: 2**, **Conceptual Completeness: 1**

This statement would duplicate all of the logic of the current `assert`, but instead of conditioning on whether a command executes successfully, it would condition on whether the block executes successfully. This behavior can currently be accomplished with a `ruby_command`, but it takes a deal of effort to copy the same logic.

#### Docker Testing

**Difficulty: 2**, **Desireability: 1**, **Conceptual Completeness: 2**

Providing integration-level tests that execute features of runbook against docker containers would give us additional test coverage to test features of runbook that use sshkit against remote hosts. Additionally, we could increase our test coverage for our sshkit-sudo functionality.

Additionally, it is worth thinking about if any changes to Runbook can help support testing runbooks created by end-users. What is needed to be able to spin up a test environment, execute a runbook, and ensure that the runbook executed successfully?

#### Tmux Command Results

**Difficulty: 2**, **Desireability: 2**, **Conceptual Completeness: 2**

It would be nice to capture output or status codes from an executed tmux command. This could be accomplished by writing the values to a file and then reading them, but it may be nice to have a more streamlined solution.

#### Step Dependencies

**Difficulty: 3**, **Desireability: 2**, **Conceptual Completeness: 2**

In some instances a step may require that a previous step be executed before it can safely execute. It would be nice if these dependencies could be codified, so when a step is skipped, you can still ensure it is executed when executing a step that depends on it. Tracking which steps have been executed would probably want to exist for the life of the execution of the runbook, so surving restarts. In an extreme case, executing a runbook may boil down to a rake-like execution. Perhaps it would be possible to make steps independently executable, and then they could be weaved into rake.

#### Update Command Counts

**Difficulty: 1**, **Desireability: 3**, **Conceptual Completeness: 1**

SSHKit has an incrementing number for each command that is executed. This incrementing number is for the entire runbook which doesn't provide a lot of value. Providing the count per step would be more informative. Additionally, the logic uses the same number for similar commands. For example if you call `ls` twice, it will use the same number each time. It would be nice if this number was more contextual. Probably the best way to accomplish this involves, creating a PR to Airbrussh to allow a context to be set via config. The context would emulate the RakeContext but have different logic for setting the current task and tracking the history of commands. It would probably make sense to make an Abstract Context that defines the required interface for a context, which is `current_task_name`, `register_new_command`, and `position`. This issue has been opened up to track this work: https://github.com/mattbrictson/airbrussh/issues/130

Helpful links:

* https://github.com/mattbrictson/airbrussh/blob/918c072254c8bf78982bb6a5e384cedc8e361836/lib/airbrussh/configuration.rb#L7
* https://github.com/mattbrictson/airbrussh/blob/918c072254c8bf78982bb6a5e384cedc8e361836/lib/airbrussh/console_formatter.rb#L19
* https://github.com/mattbrictson/airbrussh/blob/918c072254c8bf78982bb6a5e384cedc8e361836/lib/airbrussh/rake/context.rb#L47
* https://github.com/mattbrictson/airbrussh/blob/918c072254c8bf78982bb6a5e384cedc8e361836/lib/airbrussh/command_formatter.rb#L11

#### Create Plugin Generator

**Difficulty: 1**, **Desireability: 2**, **Conceptual Completeness: 2**

Creating a generator for new Runbook plugins would help to make new plugin creation easier. Additionally, it would help to enforce common patterns for new plugins. As no Runbook plugins currently exist, this feature is not a high priority at this point.

Some notes on plugins: (1) The switch for enabling a Runbook plugin should be requiring the plugin. (2) If you want to control how certain parts of the plugin are executed, this should be managed using Runbook's configuration.

#### Create Run Generator

**Difficulty: 1**, **Desireability: 3**, **Conceptual Completeness: 1**

This would make creating new runs easier. As creating new runs is a pretty rare occurrence, this feature seems unnecessary at this point, but may be nice for completeness.

#### Create View Generator

**Difficulty: 1**, **Desireability: 3**, **Conceptual Completeness: 1**

This would make creating new views easier. As creating new views is a pretty rare occurrence, this feature seems unnecessary at this point, but may be nice for completeness.

#### Outline View Option

**Difficulty: 1**, **Desireability: 3**, **Conceptual Completeness: 1**

When this option is supplied only entity nodes (book, section, step) would be rendered. This could be nice if you just want an overview of what a runbook does. I have not seen too much demand for this feature, so have not implemented it. It would add an additional option to the view CLI command.

#### Guard Runbook

**Difficulty: 2**, **Desireability: 2**, **Conceptual Completeness: 2**

It could be nice to automatically update Runbook views when a runbook file is modified. This can help identify syntax errors and keep persisted views up to date. It could be helpful to see how your changes are displayed within a Runbook view. This is the main use case I can think of for guard, but perhaps there are others?

#### Rake Task Interface

**Difficulty: 1**, **Desireability: 3**, **Conceptual Completeness: 1**

Provide a rake task interface to Runbook in addition to the ruby invocation interface and the CLI interface. This could be valuable for working with runbooks in a rake-heavy environment. There has not been specific interest in this feature, so it has not gotten prioritized.

#### Multiple Commands in Groups

**Difficulty: 3**, **Desireability: 2**, **Conceptual Completeness: 3**

When specifying to execute a command against multiple servers in groups using the `parallelization` setter, commands are executed in groups for each command, so a single command runs to completion before the next command is executed in groups. It would be nice if there was a way to group a set of commands such that all commands for the first group were executed before commands for the second group were executed. The current workaround for this is to use Ruby to define multiple steps each of which completes against its full set of servers. 

I do not have an idea of how to cleanly accomplish this.

#### Yaml Specification

**Difficulty: 2**, **Desireability: 2**, **Conceptual Completeness: 1**

Right now the only way to define your Runbook is using Ruby. When the book is evaluated, it gets stored as an intermediate data structure, which happens to be a set of Ruby objects, but the runbook could instead be represented as yaml. The yaml could define your runbook object which is then converted into a Ruby object before executing. I see two main benefits to this. (1) Having a strict data representation of a runbook will help ensure that the representation stays simple and does not get convoluted with complex logic or difficult representations. (2) This could provide an easier method of specification for people uncomfortable writing Ruby.

Actually writing a runbook in Yaml, would likely limit the ease of use and feature set for writing a runbook. Specifically, it would require a separate templating language for the yaml (instead of pure Ruby), and ruby_command blocks would need to be eval'ed, there would be no syntax highlighting or other Ruby compilation errors. It may make stack traces more difficult to read or debugging harder.

Having a yaml representation of your runbook could aid in additional analysis such as more easily detecting compatibility errors, if all required plugins are present, if there is a semantic vs. syntactic change to the runbook.

#### Runbook Web Server

**Difficulty: 3**, **Desireability: 3**, **Conceptual Completeness: 3**

It might be nice to be able to serve up a local copy of Runbook views so they could be referenced within a web browser. For some this may be more valuable than referencing them on the command line. 

#### Interactive Runbook Launcher

**Difficulty: 2**, **Desireability: 3**, **Conceptual Completeness: 3**

It might be nice to provide a cool CLI for listing and navigating the set of runbooks for a project. It could display titles and descriptions and the runbooks could be interactively launched in separate panes. This may be helpful for someone first familiarizing themselves with the runbooks associated with a project. This may depend on a great deal of customization to suite people's workflows so it may not be that valuable. It could be similar to `rake -T` on steroids.
