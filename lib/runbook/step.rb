module Runbook
  class Step
    attr_reader :title

    def initialize(title)
      @title = title
    end
  end
end
