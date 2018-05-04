require "active_support/inflector"
require "method_source"
require "pastel"
require "sshkit"
require "tty-progressbar"
require "tty-prompt"

require "runbook/errors"

require "runbook/dsl"

require "runbook/entity"
require "runbook/entities/book"
require "runbook/entities/section"
require "runbook/entities/step"

require "runbook/helpers/ssh_kit_helper"

require "runbook/runner"
require "runbook/run"
require "runbook/runs/ssh_kit"

require "runbook/viewer"
require "runbook/view"
require "runbook/views/markdown"

require "runbook/statement"
require "runbook/statements/ask"
require "runbook/statements/assert"
require "runbook/statements/command"
require "runbook/statements/confirm"
require "runbook/statements/description"
require "runbook/statements/monitor"
require "runbook/statements/note"
require "runbook/statements/notice"
require "runbook/statements/ruby_command"
require "runbook/statements/wait"

require "runbook/extensions/description"
require "runbook/extensions/sections"
require "runbook/extensions/ssh_config"
require "runbook/extensions/statements"
require "runbook/extensions/steps"

require "runbook/version"

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'SSH'
end

module Runbook
  def self.book(title, &block)
    Entities::Book.new(title).tap do |book|
      book.instance_eval(&block)
    end
  end

  def self.books
    @books ||= {}
  end

  def self.entities
    _child_classes(Runbook::Entities)
  end

  def self.statements
    _child_classes(Runbook::Statements)
  end

  def self._child_classes(mod)
    mod.constants.map { |const|
      "#{mod.to_s}::#{const}".constantize
    }.select { |const| const.is_a?(Class) }
  end
end
