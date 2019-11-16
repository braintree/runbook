require "bundler/gem_tasks"
require "rspec/core/rake_task"

spec_all = RSpec::Core::RakeTask.new(:spec_all)

spec_task = RSpec::Core::RakeTask.new(:spec)
spec_task.exclude_pattern = "spec/fullstack/**{,/*/**}/*_spec.rb"

spec_fullstack = RSpec::Core::RakeTask.new(:spec_fullstack)
spec_fullstack.pattern = "spec/fullstack/**{,/*/**}/*_spec.rb"

task :default => :spec
