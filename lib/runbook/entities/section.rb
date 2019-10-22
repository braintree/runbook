module Runbook::Entities
  class Section < Runbook::Entity
    def initialize(title, tags: [])
      super(title, tags: tags)
    end
  end
end
