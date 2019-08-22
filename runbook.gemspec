# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "runbook/version"

Gem::Specification.new do |spec|
  spec.name          = "runbook"
  spec.version       = Runbook::VERSION
  spec.authors       = ["pblesi"]
  spec.email         = ["code@getbraintree.com"]

  spec.summary       = %q{Write beautiful, executable runbooks for conducting system operations.}
  spec.description   = %q{Runbook provides a DSL for specifying system operations. This DSL is used to generate formatted runbooks as well as interactive runbooks to be executed on the command line.}
  spec.homepage      = "https://github.com/braintree/runbook/"
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 2.2.3'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport', '>= 5.0.1.x'
  spec.add_runtime_dependency "method_source", "~> 0.9"
  spec.add_runtime_dependency "sshkit", "1.16"
  spec.add_runtime_dependency "sshkit-sudo", "~> 0.1"
  spec.add_runtime_dependency "airbrussh", "~> 1.3"
  spec.add_runtime_dependency "thor", "~> 0.20"
  spec.add_runtime_dependency "tty-progressbar", "~> 0.14"
  spec.add_runtime_dependency "tty-prompt", "~> 0.16"

  spec.add_development_dependency "aruba", "~> 0.14"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "pry", "~> 0.11"
  spec.add_development_dependency "pry-byebug", "~> 3.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
