# Runbook

Runbook is a tool for defining runbooks using a Ruby DSL. Once your runbook is defined, you can use it generate a formatted representation of the book or even execute the runbook interactively. You can, for example, export your runbook to markdown or use the same runbook to automatically orchestrate a fleet of servers. Runbook provides an extendable interface for augmenting the DSL and defining your own behavior.

Runbook provides two modes for evaluating your runbook once it is defined. The first mode, view mode, allows you to export your runbook into various formats such as markdown. The second mode, run mode, allows you to execute behavior based on the statements in your runbook such as executing commands on remote servers.

Runbook provides a very flexible interface. It can be integrated into your existing projects to add orchestration functionality, installed on systems as a stand-alone executable, or runbooks can be defined to have themselves be executable. In addition to being useful for automating common tasks, runbooks are a perfect bridge for providing operations teams with step-by-step instructions for handling common issues (especially when solutions cannot be easily automated).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'runbook'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install runbook

## Runbook Anatomy

Below is an example of a runbook:

```ruby
Runbook.book "Restart Nginx" do
  description <<-DESC
This is a simple runbook to restart nginx and verify
it starts successfully
  DESC

  section "Restart Nginx" do
    server "app01.prod"
    user "root"

    step "Stop Nginx" do
      note "Stopping Nginx..."
      command "service nginx stop"
      assert %q{service nginx status | grep "not running"}
    end

    step { wait 5 }

    step "Start Nginx" do
      note "Starting Nginx..."
      command "service nginx start"
      assert %q{service nginx status | grep "is running"}
      confirm "Nginx is taking traffic"
      notice "Make sure to report why you restarted nginx"
    end
  end
end
```

### Entities, Statements, and Setters

A runbook is composed of entities, statements, and setters. Runbook entities contain either other entities or statements. Examples of entities include Books, Sections, and Steps. They define the structure of the runbook and can be considered the "nodes" of the tree structure. As entities are the nodes of the tree structure, statements are the "leaves" of the structure and comprise the various behaviors or commands of the runbook. Setters, typically referenced from within steps, associate state with the node, which can be accessed by its children.

#### Books, Sections, and Steps

Entities are composed of a title and a list of items which are their children. Each entity can be rendered with a specific view or executed with a specific run.

##### Books

Books are the root of a runbook. They are initialized as follows:

```ruby
Runbook.book "Unbalance node" do
end
```

Every book requires a title. Books can have description and section children. Descriptions describe the book and are declared with the `description` keyword.

##### Sections

A book is broken up into sections. Every section requires a title. Sections can have descriptions, other sections, or steps as children.

##### Steps

Steps hold state and group together a set of statements. Steps do not require titles or children. This allows runbooks to be very flexible. You can fill out steps as needed, or be terse when the behavior of the step is self-evident.

#### Statements

Statements are the workhorses of runbooks. They comprise all the behavior runbooks execute. Runbook comes with the following statements:

**ask**: Prompts the user for a string and stores its value in a method on the containing step entity. This value can be referenced in later statements such as the `ruby_command` statement.

```ruby
ask "What percentage of requests are failing?", into: :failing_request_percentage
```

**assert**: Runs the provided `cmd` repeatedly until it returns true. A timeout can be set and a command to be run if a timeout occurs. Commands can optionally be specified as `raw`. This tells SSHKit to not perform auto-wrapping of the commands, but execute the exact string on the remote server. See SSHKit's documentation for more details.

```ruby
assert(
  'service nginx status | grep "is running"',
  cmd_ssh_config: {servers: ["host1.prod"], parallelization: {strategy: :parallel}},
  cmd_raw: false,
  interval: 3, # seconds
  timeout: 300, # seconds
  timeout_cmd: "echo 'help' | mail -s 'need help' page-me@page-me.com",
  timeout_cmd_ssh_config: {servers: [:local], parallelization: {strategy: :parallel}},
  timeout_cmd_raw: false,
)
```

**command**: Runs the provided `cmd`. An optional `ssh_config` can be specified to configure how the command gets run. Commands also take an optional `raw` parameter that tells SSHKit whether the command should be executed as is, or to include the auto-wrapping of the ssh_config.

```ruby
command "service nginx start", ssh_config: {servers: ["host1.prod", "host2.prod"], parallelization: {strategy: :groups}}
```

**confirm**: Proposes the prompt to the user and exits if the user does not confirm the prompt.

```ruby
confirm "Asset requests have started trickling to the box"
```

**description**: Prints the description in an unformatted manner to the user

```ruby
description <<-DESC
This message will print directly to the user as written, without
additional formatting.
DESC
```

**monitor**: Print the `cmd` out to the user and `prompt` the user to ensure the monitoring requirement has been met. This is a more manual version of the `assert` statement.

```ruby
monitor(cmd: "tail -Fn 100 /var/log/nginx.log", prompt: "User requests are no longer failing")
```

**note**: Print a short note to the user.

```ruby
note "This operation kills all zombie processes"
```

**notice**: Print out an important message to the user.

```ruby
notice "There be dragons!"
```

**ruby_command**: Executes its block in the context of the execution process. The block is passed the ruby_command statement and the execution metadata as arguments. Additionally, the block has access to all helpers and behaviors available to other statements being executed.

```ruby
ruby_command do |rb_cmd, metadata|
  if (failure_rate = rb_cmd.parent.failing_request_percentage) > 25
    `echo 'Help! failure rate at #{failure_rate}' | mail -s 'High failure rate!' page-me@page-me.com`
  else
    `echo "Experienced failure rate of #{failure_rate}" | mail -s 'Help me eventually' not-urgent@my_site.com`
  end
end
```

Metadata at execution time is structured as follows:

```ruby
{
  depth: 1, # The depth within the tree (book starts at depth 1)
  index: 0, # The index of the item in terms of it's parent's children (starts at 0 for first child)
  position: "1.1", # A string representing your current position within the tree
  noop: false, # A boolean indicating if you are running in noop mode. ruby_command blocks are never evaluated in noop mode
  auto: false, # A boolean indicating if you are running in auto mode
  start_at: 0, # A string representing the string where nodes should start being processed
  toolbox: Runbook::Toolbox.new, # A collection of methods to invoke side-effects such as printing and collecting input
}
```

Additional methods that the `ruby_command` block has access to are:

 * `metadata[:toolbox].prompt`: A `TTY::Prompt` for retrieving input from the user
 * `metadata[:toolbox].ask(msg)`: retrieve user input
 * `metadata[:toolbox].yes?(msg)`: provide the user with a yes/no prompt
 * `metadata[:toolbox].output(msg)`: output text to the user
 * `metadata[:toolbox].warn(msg)`: output warning text to the user
 * `metadata[:toolbox].error(msg)`: output error text to the user
 * `metadata[:toolbox].exit(return_value)`: exit the process with the specified response code

**wait**: Sleep for the specified amount of time (in seconds)

```ruby
wait 5
```

#### Setters

Setters set state on the parent item, typically the containing step. Runbook comes with the following setters:

**set**: Creates a method named "key" on the step that provides a value of "value". This method can be referenced in the `ruby_command` statement to get access to compile-time values at runtime.

```ruby
set :key, "value"
```

**parallelization**: Specifies the SSHKit parallelization parameters for all commands in the entity. The default parallelization strategy is `:parallel`. See SSHKit for more details on these options.

```ruby
parallelization strategy: :parallel, limit: 2, wait: 2
```

**server**: Specifies the server to use for all commands in the entity. This command in conjunction with `servers` are declarative and overwrite each other. So if you specify `server` once, `servers` twice and finally, `server` again, only the last designation will be used to run the commands.

```ruby
server "db01.qa"
```

**servers**: Used to specify a list of servers for the entity. All commands contained in this entity will be run against this list of servers (unless they have been overridden by a lower config.)

```ruby
servers "app01.qa", "app02.qa"
```

**path**: Specify the path from which commands in this step will execute.

```ruby
path "/home/sholmes"
```

**user**: Specify the user that the command will be run as

```ruby
user "root"
```

**group**: Specify the effective group the commands will be run as

```ruby
group "devs"
```

**env**: Specify the environment for the commands

```ruby
env {rails_env: :production}
```

**umask**: Specify the umask the commands will be run with

```ruby
umask "077"
```

Additionally, `Step` provides an `ssh_config` helper method for generating ssh_configs that can be passed to command statements.

```ruby
step do
  cmd_ssh_config = ssh_config do
    server "host1.qa"
    user "root"
  end
  command "echo $USER", ssh_config: cmd_ssh_config
end
```

## Configuration

Runbook is configured using its configuration object. Below is an example of how to configure Runbook.

```ruby
Runbook.configure do |config|
  config.ssh_kit.umask = "077"
  config.ssh_kit.default_runner_config = {in: :groups, limit: 5}
  config.ssh_kit.default_env = {rails_env: :staging}

  config.enable_sudo_prompt = true
  config.use_same_sudo_password = true
end
```

If the `ssh_kit` configuration looks familiar, that's because it's an SSHKit Configuration object. Any configuration options set on `SSHKit.config` can be set on `config.ssh_kit`.

### Configuration Files

Runbook automatically loads configuration from a number of predefined files. Runbook will attempt to load configuration from the following locations on startup: `/etc/runbook.conf`, a `Runbookfile` in a parent directory from the current directory, a `.runbook.conf` file in the current user's home directory, a file specified with `--config` on the command line, any configuration specified in a runbook. Runbook will also load configuration from these files in this order of preference, respectively. That is, configuration values specified at the project level (`Runbookfile`) will override configuration values set at the global level (`/etc/runbook.conf`), etc. 

## Working With Runbooks

You can integrate with Runbook in several different ways. You can create your own project or incorporate Runbook into your existing projects. You can user Runbook via the command line. And you can even create self-executing runbooks.

### From Within Your Project

Runbooks can be executed using the `Runbook::Viewer` and `Runbook::Runner` classes.

#### Executing a runbook using `Runbook::Viewer`

```ruby
Runbook::Viewer.new(book).generate(:markdown)
```

In this case book is a `Runbook::Entities::Book` and `:markdown` refers to the specific view type (`Runbook::Views::Markdown`).

#### Executing a runbook using `Runbook::Runner`

```ruby
Runbook::Runner.new(book).run(run: :ssh_kit, noop: false, auto: false, paranoid: true, start_at: 0)
```

This will execute `book` using the `Runbook::Runs::SSHKit` run type. It will not run the book in `noop` mode. It will not run the book in `auto` mode. It will run the book in `paranoid` mode. And it will start at the beginning of the book. Noop mode runs the book without side-effects outside of printing what it will execute. Auto mode will skip any prompts in the runbook. If there are any required prompts in the runbook (such as the `ask` statement), then the run will fail. Paranoid mode will prompt the user for whether they should continue at every step. Finally `start_at` can be used to skip parts of the runbook or to restart at a certain point in the event of failures, stopping and starting the runbook, etc.

### Via The Command Line

Runbook can be used to write stand-alone runbook files that can be executed via the command line. Below is a list of examples of how to use Runbook via the command line.

Get Runbook usage instructions

```sh
$ runbook help
```

Render `my_runbook.rb` in the default view format (markdown)

```sh
$ runbook view my_runbook.rb
```

Execute `my_runbook.rb` using the default executor (ssh_kit)

```sh
$ runbook exec my_runbook.rb
```

Execute `my_runbook.rb` in no-op mode, preventing commands from executing.

```sh
$ runbook exec --noop my_runbook.rb
```

Execute `my_runbook.rb` in auto mode. Runbooks that are executed in auto mode do not prompt the user for input.

```sh
$ runbook exec --auto my_runbook.rb
```

Execute `my_runbook.rb` starting at position 1.2.1. All prior steps in the runbook will be skipped

```sh
$ runbook exec --start-at 1.2.1 my_runbook.rb
```

Execute `my_runbook.rb` without confirmation between each step

```sh
$ runbook exec --no-paranoid my_runbook.rb
```

Environment variables can be specified via the command line, modifying the behavior of
the runbook at runtime.

```sh
$ HOSTS="appbox{01..30}.prod" ENV="production" runbook exec --start-at 1.2.1 my_runbook.rb
```

### Self executable

Runbooks can be written to be self-executable

```ruby
#!/usr/bin/env ruby
# my_runbook.rb
require "runbook"

runbook = Runbook.book "Say hello to world" do
  section "Address the world" do
    step { command "echo 'hello world!'" }
    step { confirm "Has the world received your greeting?" }
  end
end

# Register your runbooks with your file's basename to ensure better `ruby_command` rendering
Runbook.books[:my_runbook] = runbook

if __FILE__ == $0
  Runbook::Runner.new(runbook).run
else
  runbook
end
```

This runbook can be executed via the command line or evaluated from within an existing project

```sh
$ ./my_runbook.rb
```

```ruby
load "my_runbook.rb"
runbook = Runbook.books[:my_runbook]
# (Or alternatively `runbook = eval(File.read("my_runbook.rb"))`)
Runbook::Runner.new(runbook).run(auto: true)
```

## Best Practices

The following are best practices when developing your own runbooks.

### Iterative automation

Runbooks allow for a very gradual transition from entirely manual operations to full automation. Runbooks can start out as a simple outline of all steps required to carry out an operation. From there, commands and prompts can be added to the runbook, actually carrying out and replacing the manual processes. 

Monitoring can transition from a process required by a human into something that can be codified and executed by your runbook. Eventually, the runner's `auto` flag can be used to allow the runbook to run uninterrupted without any human intervention. These runbooks can be triggered automatically in response to detected events. This will allow you to do more important things with your time, like eat ice cream.

### Parameterizing Runbooks

You will typically want to parameterize your runbooks so they can be run against different hosts or in different environments. Because runbooks are Ruby, you have a multitude of options for parameterizing your runbooks, from config files, to getting host information via shell commands, to using environment variables. Here's an example of a few of these methods:

```ruby
host = ENV["HOST"] || "<host>"
replication_host = ENV["REPLICATION_HOST"] || "<replication_host>"
env = `facter environment`
rails_env = `facter rails_env`
customer_list = File.read("/tmp/customer_list.txt")
```

### Execution Best Practices

As a best practice, Runbooks should always be nooped before they are run. This will allow you to catch runtime errors such as using the ask statement when running in auto mode, typos in your runbooks, and to visually confirm what will be executed. 

Additionally, it can be nice to have a generated view of the runbook you are executing to have a good high-level overview of the steps in the runbook. 

### Composing Runbooks

Runbooks can be composed using the `add` keyword. Below is an example of composing a runbook from smaller, reusable components.

```ruby
restart_services_section = Runbook.section "Restart all services" do
  step "Restart nginx"
  step "Restart postgres"
end

Runbook.book "Update configuration" do
  section "Change config" do
    command "sed -i 's/listen 8080;/listen 80;/' /etc/nginx/nginx.conf"
  end

  add restart_services_section
end
```

### Deep Nesting

Because the Runbook DSL is declarative, it is generally discouraged to develop elaborate nested decision trees. For example, it is discouraged to use the `ask` statement to gather user feedback, branch on this information in a `ruby_command`, and follow completely separate sets of steps. This is because deep nesting eliminates the benefits of the declarative DSL. You can no longer noop the deeply nested structure for example. 

If you are looking to make a complex decision tree, it is recommended that you do this by composing separate runbooks or entities and nooping those entities separately to ensure they work as expected. Below is an example of a few different ways to compose nested runbooks

```ruby
step "Inspect plate" do
  ask "What's on the plate?", into: :vegetable
  ruby_command do |rb_cmd, metadata|
    case (veggie = rb_cmd.parent.vegetable)
    when "carrots"
      carrots_book.run(self, metadata.dup)
    when "peas"
      system("runbook exec samples/print_peas.rb")
    else
      metadata[:toolbox].warn("Found #{veggie}!")
    end
  end
end
```

The first delegation `carrots_book.run` evaluates the book in the context of the current runbook. Sections and steps become sub-sections and sub-steps of the current step. The second delegation spins up an entirely new process to run the `print_peas` runbook in isolation. Either delegation could be preferred, depending on your needs.

### Load vs. Eval

When loading your runbooks from files, you have two options at your disposal:

```ruby
load "my_runbook.rb"
runbook = Runbook.books[:my_runbook] # Requires that the runbook registers itself when it's defined.
```

and

```ruby
runbook = eval(File.read("my_runbook.rb"))
```

Loading your runbook file is more ideal, but adds slight complexity. This method is prefered because the Ruby mechanism for retrieving source code does not work for code that has been `eval`ed. This means that you will not see `ruby_command` code blocks in view and noop output when using the `eval` method. You will see an "Unable to retrieve source code" message instead.

## Extending Runbook

Runbook is built from the ground up to be extendable.

### Adding Runs and Views

You can add new run and view types by defining modules under `Runbook:::Runs` and `Runbook::Views` respectively. They will automatically be accessible from the command line or via the `Runner` and `Viewer` classes. See `lib/runbook/runs/ssh_kit.rb` or `lib/runbook/views/markdown.rb` for examples of how to implement runs and views.

```ruby
module Runbook::Views
  module Yaml
    include Runbook::View

    # handler names correspond to the entity or statement class name
    # Everything is underscored and "::" is replaced by "__"
    def self.runbook__entities__book(object, output, metadata)
      output << "---\n"
      output << "book:\n"
      output << "  title: #{object.title}\n"
    end

    # Add other handlers here
  end
end
```

### DSL Extensions

You can add arbitrary keywords to your entity DSLs. For example, I could add an alias to Runbook's Book DSL as follows:

```ruby
module MyRunbook::Extensions
  module Aliases
    module DSL
      def s(title, &block)
        section(title, &block)
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Aliases::DSL)
end
```

### Adding New Statements

In order to add a new statement to your DSL, create a class under `Runbook::Statements` that inherits from `Runbook::Statement`. This statement will be initialized with all arguments passed to the corresponding keyword in the DSL. Remember to also add a corresponding method to runs and views so your new statement can be interpretted in each context.

```ruby
module Runbook::Statements
  class Diagram < Runbook::Statement
    attr_reader :alt_text, :url

    def initialize(alt_text, url)
      @alt_text = alt_text
      @url = url
    end
  end
end
```

In the above example a keyword `diagram` will be automatically added to the step dsl and its arguments will be used to initialize the Diagram object.

### Adding Run and View Functionality

You can add handlers for new statements and entities to your runs and views by prepending the modules with the new desired functionality.

```ruby
module MyRunbook::Extensions
  module Diagram
    def self.runbook__entities__diagram(object, output, metadata)
      output << "![#{object.alt_text}](#{object.url})"
    end
  end

  Runbook::Views::Markdown.prepend(Diagram)
end
```

If you are not modifying existing methods, you can simply re-open the module to add new methods.

### Adding New Run Behaviors

Every Entity and Statement gets access to a Toolbox in `metatada[:toolbox]`. This toolbox is used to provide methods with side effects (such as printing messages) when rendering and running your runbooks. Addtional behaviors can be added to the toolbox by prepending `Runbook::Toolbox`.

```ruby
module MyRunbook::Extensions
  module Logger
    def initialize
      super
      log_file = ENV["LOG_FILE"] || "my_log_file.log"
      @logger = Logger.new(log_file)
    end

    def log(msg)
      @logger.info(msg)
    end
  end

  Runbook::Toolbox.prepend(Logger)
end
```

Now you can access `log` in your handler functionality

```ruby
module MyRunbook::Extensions
  module Logging
    def self.runbook__entities__book(object, metadata)
      super
      metadata[:toolbox].log("Executing #{object.title}")
    end
  end

  Runbook::Runs::SSHKit.prepend(Logging)
end
```

### Adding to Runbook's Configuration

You can add additional configuration to Runbook's configuration by prepending to Runbook::Configuration.

```ruby
module MyRunbook::Extensions
  module Configuration
    attr_accessor :log_level

    def initialize
      super
      self.log_level = :info
    end
  end

  Runbook::Configuration.prepend(Configuration)
end
```

This will add a `log_level` attribute to Runbook's configuration with a default value of `:info`.

## Known Issues

### Command Quoting

Because ssh_config declarations such as `user`, `group`, `path`, `env`, and `umask` are implemented as wrappers around your provided commands, you must be aware that issues can arise if your commands contain characters such as single quotes that are not properly escaped.

As of SSHKit 1.16, declaring the above five ssh_config declarations will produce an ssh command similar to the following:

```
cd /home/root && umask 077 && ( export RAILS_ENV="development" ; sudo -u root RAILS_ENV="development" -- sh -c 'sg root -c \"/usr/bin/env echo I love cheese\"' )
```

One specific known issue due to improperly escaped characters is when providing a user declaration, any single quotes should be escaped with the following string: `'\\''`

```
command "echo '\\''I love cheese'\\''"
```

Alternatively, if you wish to avoid issues with SSHKit command wrapping, you can specify that your commands be executed in raw form, passed directly as written to the specified host.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/braintree/runbook. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Feature Requests

Any feature requests are always welcome and will be considered in accordance with time and need. Additionally, I have a few feature requests of my own and would appreciate anyone interested in picking them up. They are stored in TODO.md. If you choose to contribute, your contributions will be greatly appreciated.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Runbook project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/braintree/runbook/blob/master/CODE_OF_CONDUCT.md).
