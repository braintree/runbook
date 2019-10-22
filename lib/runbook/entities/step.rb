module Runbook::Entities
  class Step < Runbook::Entity
    def initialize(title=nil, tags: [])
      super(title, tags: tags)
    end
  end
end
