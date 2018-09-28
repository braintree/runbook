module Runbook::Entities
  class Book < Runbook::Entity
    def initialize(title)
      super(title)
    end

    # Seed data for 'render' tree traversal method
    def self.initial_render_metadata
      {depth: 1, index: 0}
    end

    # Seed data for 'run' tree traversal method
    def self.initial_run_metadata
      {depth: 1, index: 0, position: ""}
    end
  end
end
