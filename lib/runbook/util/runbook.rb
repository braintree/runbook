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

  def self.deprecator
    return @deprecator if @deprecator
    major_version = Gem::Version.new(Runbook::VERSION).segments[0]
    next_major_version = major_version + 1
    @deprecator = ActiveSupport::Deprecation.new(
      "#{next_major_version}.0",
      "Runbook"
    )
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
