# Runbook Vision

Runbook is a tool for defining runbooks using a Ruby DSL. Runbook provides an extendable interface for augmenting the DSL and defining your own behavior based on the DSL.

An example of the DSL is as follows:

```ruby
require "runbook"

host = ENV["HOST"] || "<host>"
replication_host = ENV["REPLICATION_HOST"] || "<replication_host>"
env = `bt-facter environment`
rails_env = `bt-facter rails_env`

Runbook.book "Drop Redis" do
  section "Prep in QA" do
    step "Deploy GW"
    step "Start script to run payment_method updates, transaction create"
  end

  section "Setup" do
    step "Ensure hot swapping code is deployed" do
      confirm "is version 03ee05d124b8a7caf90ebf48d3e877eb2206f2f1 deployed?"
    end

    step { confirm "is ~/replication_redis.sh on #{host}?" }
    step { confirm "is ~/replication_buffer.rb on #{host}?" }
    step { confirm "is ~/flip_redis_feature_switches.rb on background01?" }
    step { confirm "is node to drop (#{host}) listed second in the global config?" }

    step "Install rdbtools" do
      server host
      command "sudo pip install rdbtools"
    end

    step "Run ~/flip_redis_feature_switches.rb" do
      server "background01.prod"
      command "sudo -u root RAILS_ENV=#{rails_env} bundle exec rails runner ~/flip_redis_feature_switches.rb"
    end
  end

  section "Perform Replication" do
    step { command "./replication.sh" }

    step %Q{Set \`dir\` to \`/tmp\` for \`#{host}\`} do
      server host
      command "CONFIG SET dir /tmp"
      notice "This is where the dump file will be saved"
    end

    step "Stream the snapshot and replication commands from #{host} to a file" do
      command %q{echo -e "*1\r\n\$4\r\nSYNC\r\n" > /tmp/sync_command}
      command <<-COMMAND
        nc -q -1 #{host} 6379 \
        > /tmp/source_redis_host_replication_log \
        < /tmp/sync_command
      COMMAND
    end

    step "Wait for the dump to finish" do
      command "redis-cli -h #{host} -p 6379 INFO | grep rdb_bgsave_in_progress:0"
      ask "How many messages are left", into: :num_messages_left
      ruby_command do |statement, metadata|
        if metadata[:parent].num_messages_left.to_i > 5
          puts "There are more messages than we expect. Exiting..."
          exit(1)
        end
      end
    end

    step "Stream snapshot and replication log into destination" do
      note "If snapshot import fails, it is safe to rerun the entire import"
      note "If log playback fails, restart the playback at the last known good offset + 1"
      command "ruby replication_buffer.rb /tmp/source_redis_node_replication_log > >(redis-cli -h #{replication_host} -p 6379 --pipe)"
      confirm "is version 03ee05d124b8a7caf90ebf48d3e877eb2206f2f1 deployed?"
    end

    section "Ensure replication logs are caught up" do
      step %q{Call `SET replication-marker test-value` on #{host}}
      step %q{Call `GET replication-marker` on #{replication_host}}
      step { confirm "Replication script offset matches file size" }
    end
  end

  section "Drop #{host}" do
    step %q{Enable `bypass_feature_cache_for_redis_config_lookup` feature} do
      confirm "Have you waited 2 minutes for the cache to clear?"
    end

    step "Verify database load is acceptable" do
      note link("https://grafana.com/dashboard/db/gateway-pgbouncer")
      note "pgcluster04a in #{link("https://grafana.com/dashboard/db/db-metrics")}"
    end

    step "Enable feature to stop reading from and writing to #{host}" do
      confirm "Have you enabled the \`enable_single_node_redis\` feature?"
      note "Any in-flight requests could potentially hold stale clients here"
      note "As the client change cascades, old and new clients could write invalid data due to a race condition"
    end

    step "Verify reads and writes are not happening on #{host} do
      note link("https://grafana.com/grafana/dashboard/db/gateway-redis")
    end

    step "Ensure replication log is no longer being written to" do
      monitor (
        cmd: "tail -f /tmp/source_redis_node_replication_log",
        confirm: "The replication log is no longer being written to"
      )
    end

    step %q{Disable `bypass_feature_cache_for_redis_config_lookup` feature} do
      confirm "Have you waited 2 minutes for the cache to clear?"
    end
  end

  section "Tear Down" do
    step "Kill processes managed by \`replication_redis.sh\`" do
      confirm "Did you type 'kill' into the script?"
    end

    step "Ensure all processes have been killed by cleanup script" do
      monitor command: "ps aux | grep redis", confirm: "There are no more redis processes"
      monitor command: "ps aux | grep tail", confirm: "There are no more tails"
    end

    step "Uninstall rdbtools on #{host}" do
      server host
      command "sudo pip uninstall rdbtools"
      confirm "Is /tmp/sync_command removed?"
    end

    step { command "rm /tmp/dump.rb" }
    step { command "rm /tmp/source_redis_node_replication_log" }
    step { confirm "Is the replication-marker key removed?" }
    step "Set global redis hosts for #{env} to contain single node in infra repo"
    step "Puppet changes to gateway_code_servers"
    step "Bounce gateway_code_servers"

    step "Set dir to a writeable directory" do
      servers [replication_host, host]
      command "config set dir /tmp"
    end

    step "Set #{host} as slaveof #[replication_host}" do
      server host
      command "slaveof #{replication_host} 6379"
    end
  end
end
```

Here's an example of a self executable runbook

```ruby
#!/usr/bin/env ruby
require "runbook"

runbook = Runbook.book "Say hello to world" do
  section "Address the world" do
    step { command "echo 'hello world!'" }
    step { confirm "Has the world received your greeting?" }
  end
end

if __FILE__ == $0
  Runbook::Runner.run(runbook)
else
  runbook
end
```

Additional statements include:

 * `assert`: Run a command with a specified interval until no error is returned. Could have timeout and execute behavior on timeout
 * `ask`: Collect user input for future ruby command blocks
 * `ruby_command`: A block of arbitrary ruby code to be executed in the context of the step at runtime
 * `wait`: Sleep for a specified period of time

CLI interface examples:

```
$ runbook help
```

```
$ runbook view my_runbook.rb
```

```
$ runbook view --output org-mode my_runbook.yml
```

```
$ cat my_runbook.rb | runbook view --input ruby --output yaml --file my_runbook.yml
```

```
$ runbook run my_runbook.rb
```

```
$ runbook run --noop my_runbook.rb
```

```
$ runbook run --noop --skip-prompts my_runbook.rb
```

```
$ runbook run --noop --start-at 1.2.1 my_runbook.rb
```

```
$ HOSTS="appbox{01..30}.prod" ENV="production" runbook run --start-at 1.2.1 my_runbook.rb
```

```
$ ./my_runbook.rb
```

## Feature list

* [x] Allow sections to inherit from sections
* [x] Add way to track depth of a current object in the tree
* [x] Add a way to introspect on your neighbors or place in the tree
* [x] Allow some sort of description statement at the section level
* [] Allow step-level configuration for the following:
  * parallelization [:parallel, :groups, :sequence], :limit, :wait
  * path
  * user
  * group
  * env
  * umask
* Generation plugins
  * Can specify additional generators for output of the runbook
* Pluggable runbook functionality
  * You can augment the runbook's default keywords with additional keywords to suite your needs and add extra functionality
  * You can for example create a layout declaration that is executed for your runbooks
  * You can hook in to existing keywords to add additional functionality (such as copying all commands to the clipboard)
* Runbook lifecycle hooks
  * Can hook into various points of the execution of a runbook to add functionality
  * Example includes adding an option to take notes at each step or logging the run
* Handles ctrl-c gracefully
* Should provide an option to suppress warnings
* Will need some sort of configuration for the runbook
* Create a generator for a runbook? Allow for custom generators?
* Guard for view updates (How to handle arguments?)
* Could provide a rake task for compiling and nooping runbooks?
* Be able to serve up markdown docs (web server) for easy viewing
* Compile-time validations?
* Can specify input-format, output-format, input (file), and output (file)
* Yaml specification format (subset of Ruby)
  * Will not contain as much flexibility as Ruby format
  * Can convert from Ruby format to yaml (depending on compatibility) and yaml to Ruby

Document:

* [x] Command line interface (without prompts, noop, resume/continue/start at specific step)
  * Reads from standard in, writes to standard out
* Ruby interface
  * You can integrate and execute runbooks from within your existing projects
* Runbooks can be self-contained/runnable files
* Generate markdown
  * Different generators can be used for different types of markdown or generally for different formatting
* Seamlessly integrates with other Ruby libraries (for augmenting functionality)
* Demonstrate how to add aliases for keywords


## Architecture

./lib/runbook.rb # Contains configure and book commands
./exe/runbook # Command line app for interacting with runbook (likely Thor)
./lib/runbook/cli.rb
./lib/runbook/book.rb # Top-level book object; include from_yaml method
./lib/runbook/runner.rb # Object for exectuting runbooks
./lib/runbook/section.rb # Sections within a runbook
./lib/runbook/step.rb # Steps within a section
./lib/runbook/viewer.rb # Object for viewing runbooks
./lib/runbook/views/markdown.rb # Object for rendering markdown
./lib/runbook/views/ruby.rb # Object for rendering ruby
./lib/runbook/views/yaml.rb # Object for rendering yaml
./lib/runbook/helpers/link.rb # Helper objects used within books, sections, steps, and statements
./lib/runbook/statements/ask.rb
./lib/runbook/statements/assert.rb
./lib/runbook/statements/capture.rb
./lib/runbook/statements/command.rb
./lib/runbook/statements/confirm.rb
./lib/runbook/statements/monitor.rb
./lib/runbook/statements/note.rb
./lib/runbook/statements/notice.rb
./lib/runbook/statements/ruby_command.rb
./lib/runbook/statements/wait.rb
./lib/runbook/extensions/copy_commands.rb
./lib/runbook/extensions/tmux.rb

## Open Questions

### Potential command frameworks

* https://github.com/piotrmurach/tty-command
* capistrano

### Potential command line frameworks

* Thor

### How to integrate guard
### How will the helpers work?
### Is monitor to brittle of a context for a statement?
### Is the set of statements minimalistic?
### If skip-prompts is set, a warning should be displayed if this may cause issues (e.x. ask statement)

## Additional TODO

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
