module Runbook::Entities
  class Setup < Runbook::Entity
    def initialize(tags: [], labels: {})
      super("Setup", tags: tags, labels: labels)
    end
  end
end
