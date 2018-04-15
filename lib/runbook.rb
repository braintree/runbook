require "active_support/inflector"
require "runbook/book"
require "runbook/section"
require "runbook/statements/ask"
require "runbook/statements/assert"
require "runbook/statements/command"
require "runbook/statements/condition"
require "runbook/statements/confirm"
require "runbook/statements/monitor"
require "runbook/statements/note"
require "runbook/statements/notice"
require "runbook/statements/wait"
require "runbook/step"
require "runbook/version"

module Runbook
  def self.book(title, &block)
    Book.new(title).tap do |book|
      book.instance_eval(&block)
    end
  end

  def self.statements
    consts = Runbook::Statements.constants.map do |const|
      "Runbook::Statements::#{const}".constantize
    end
    consts.select { |const| const.is_a?(Class) }
  end

  def self.statement_methods
    statements.map do |klass|
      klass.to_s.split("::")[-1].underscore
    end
  end
end
