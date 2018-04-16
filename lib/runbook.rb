require "active_support/inflector"

require "runbook/entity"
require "runbook/entities/book"
require "runbook/entities/section"
require "runbook/entities/step"

require "runbook/viewer"

require "runbook/statement"
require "runbook/statements/ask"
require "runbook/statements/assert"
require "runbook/statements/command"
require "runbook/statements/condition"
require "runbook/statements/confirm"
require "runbook/statements/monitor"
require "runbook/statements/note"
require "runbook/statements/notice"
require "runbook/statements/wait"

require "runbook/extensions/sections"
require "runbook/extensions/server_list"
require "runbook/extensions/statements"
require "runbook/extensions/steps"

require "runbook/version"

module Runbook
  def self.book(title, &block)
    Entities::Book.new(title).tap do |book|
      book.instance_eval(&block)
    end
  end

  def self.statements
    _child_classes(Runbook::Statements)
  end

  def self._child_classes(modgule)
    modgule.constants.map { |const|
      "#{modgule.to_s}::#{const}".constantize
    }.select { |const| const.is_a?(Class) }
  end
end
