module Runbook::Entities
  class Section < Runbook::Entity
    def initialize(title, tags: [], labels: {})
      super(title, tags: tags, labels: labels)
    end
  end
end
