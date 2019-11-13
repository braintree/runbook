module Runbook
  class AirbrusshContext
    attr_reader :history, :current_task_name

    def initialize(config=Airbrussh.configuration)
      @history = []
    end

    def register_new_command(command)
      hist_entry = command.to_s
      first_execution = history.last != hist_entry
      history << hist_entry if first_execution
      first_execution
    end

    def position(command)
      history.rindex(command.to_s)
    end

    def set_current_task_name(task_name)
      @current_task_name = task_name
      history.clear
    end
  end
end
