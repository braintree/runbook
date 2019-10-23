module Runbook::Entities
  class Step < Runbook::Entity
    def initialize(title=nil, tags: [], labels: {})
      super(title, tags: tags, labels: labels)
    end
  end
end
