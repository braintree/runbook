module Runbook
  def self.entities
    _child_classes(Runbook::Entities)
  end

  def self.statements
    _child_classes(Runbook::Statements)
  end

  def self.runs
    _child_modules(Runbook::Runs)
  end

  def self.generators
    _child_classes(Runbook::Generators)
  end

  def self._child_classes(mod)
    mod.constants.map { |const|
      "#{mod.to_s}::#{const}".constantize
    }.select { |const| const.is_a?(Class) }
  end

  def self._child_modules(mod)
    mod.constants.map { |const|
      "#{mod.to_s}::#{const}".constantize
    }.select { |const| const.is_a?(Module) }
  end
end
