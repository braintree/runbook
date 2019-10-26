require "tmpdir"
require "yaml"
require "thread"

require "active_support/inflector"
require "method_source"
require "pastel"
require "sshkit"
require "sshkit/sudo"
require "airbrussh"
require "tty-progressbar"
require "tty-prompt"
require "thor/group"

require "runbook/configuration"

require "hacks/ssh_kit"

require "runbook/dsl"
require "runbook/errors"
require "runbook/hooks"

require "runbook/util/repo"
require "runbook/util/runbook"
require "runbook/util/sticky_hash"
require "runbook/util/stored_pose"

require "runbook/node"

require "runbook/entity"
require "runbook/entities/book"
require "runbook/entities/section"
require "runbook/entities/setup"
require "runbook/entities/step"

require "runbook/statement"
require "runbook/statements/ask"
require "runbook/statements/assert"
require "runbook/statements/capture"
require "runbook/statements/capture_all"
require "runbook/statements/command"
require "runbook/statements/confirm"
require "runbook/statements/description"
require "runbook/statements/download"
require "runbook/statements/layout"
require "runbook/statements/note"
require "runbook/statements/notice"
require "runbook/statements/ruby_command"
require "runbook/statements/tmux_command"
require "runbook/statements/upload"
require "runbook/statements/wait"

require "runbook/helpers/format_helper"
require "runbook/helpers/ssh_kit_helper"
require "runbook/helpers/tmux_helper"

require "runbook/runner"
require "runbook/run"
require "runbook/runs/ssh_kit"

require "runbook/toolbox"

require "runbook/viewer"
require "runbook/view"
require "runbook/views/markdown"

require "runbook/generators/base"
require "runbook/generators/dsl_extension/dsl_extension"
require "runbook/generators/generator/generator"
require "runbook/generators/project/project"
require "runbook/generators/runbook/runbook"
require "runbook/generators/statement/statement"

require "runbook/extensions/add"
require "runbook/extensions/description"
require "runbook/extensions/shared_variables"
require "runbook/extensions/sections"
require "runbook/extensions/setup"
require "runbook/extensions/ssh_config"
require "runbook/extensions/statements"
require "runbook/extensions/steps"
require "runbook/extensions/tmux"

require "runbook/version"

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'SSH'
end

module Runbook
  def self.book(title, &block)
    Configuration.load_config
    Entities::Book.new(title).tap do |book|
      book.dsl.instance_eval(&block)
      register(book)
    end
  end

  def self.section(title, &block)
    Configuration.load_config
    Entities::Section.new(title).tap do |section|
      section.dsl.instance_eval(&block)
    end
  end

  def self.setup(&block)
    Configuration.load_config
    Entities::Setup.new.tap do |setup|
      setup.dsl.instance_eval(&block)
    end
  end

  def self.step(title=nil, &block)
    Configuration.load_config
    Entities::Step.new(title).tap do |step|
      step.dsl.instance_eval(&block) if block
    end
  end

  def self.register(book)
    books << book
  end

  def self.books
    @books ||= []
  end
end
