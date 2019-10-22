module Runbook::Entities
  class Setup < Runbook::Entity
    def initialize(tags: [])
      super("Setup", tags: tags)
    end
  end
end
