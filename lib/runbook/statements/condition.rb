module Runbook::Statements
  class Condition
    attr_reader :predicate, :if_stmt, :else_stmt

    def initialize(predicate: , if_stmt: , else_stmt: nil)
      @predicate = predicate
      @if_stmt = if_stmt
      @else_stmt = else_stmt
    end
  end
end
