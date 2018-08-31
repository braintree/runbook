module Runbook::Helpers
  module TmuxHelper
    def setup_layout(structure, runbook_title:)
      _remove_stale_layouts
      layout_file = _layout_file(_slug(runbook_title))
      if File.exists?(layout_file)
        stored_layout = ::YAML::load_file(layout_file)
        if _all_panes_exist?(stored_layout)
          return stored_layout
        end
      end

      _setup_layout(structure).tap do |layout_panes|
        File.open(layout_file, 'w') do |f|
          f.write(layout_panes.to_yaml)
        end
      end
    end

    def _layout_file(runbook_title)
      `tmux display-message -p "#{Dir.tmpdir}/runbook_layout_\#{pid}_\#{session_name}_\#{pane_pid}_\#{pane_id}_#{runbook_title}.yml"`.strip
    end

    def _slug(title)
      title.titleize.gsub(/\s+/, "").underscore.dasherize
    end

    def _all_panes_exist?(stored_layout)
      (stored_layout.values - _session_panes).empty?
    end

    def _remove_stale_layouts
      session_panes = _session_panes
      session_layout_files = _session_layout_files
      session_layout_files.each do |file|
        File.delete(file) unless session_panes.any? { |pane| /_#{pane}_/ =~ file }
      end
    end

    def _session_panes
      `tmux list-panes -s -F '#D'`.split("\n")
    end

    def _session_layout_files
      session_layout_glob = `tmux display-message -p "#{Dir.tmpdir}/runbook_layout_\#{pid}_\#{session_name}_*.yml"`.strip
      Dir[session_layout_glob]
    end

    def _setup_layout(structure)
      current_pane = _runbook_pane
      panes_to_init = []
      {}.tap do |layout_panes|
        if structure.is_a?(Hash)
          first_window = true
          structure.each do |name, window|
            if first_window
              _rename_window(name)
              first_window = false
            else
              current_pane = _new_window(name)
            end
            _setup_panes(layout_panes, panes_to_init, current_pane, window)
          end
        else
          _setup_panes(layout_panes, panes_to_init, current_pane, structure)
        end
        _swap_runbook_pane(panes_to_init, layout_panes)
        _initialize_panes(panes_to_init, layout_panes)
      end
    end

    def send_keys(command, target)
      `tmux send-keys -t #{target} '#{command}' C-m`
    end

    def _setup_panes(layout_panes, panes_to_init, current_pane, structure, depth=0)
      return if structure.empty?
      case structure
      when Array
        case structure.size
        when 1
          _setup_panes(layout_panes, panes_to_init, current_pane, structure.shift, depth+1)
        else
          size = 100 - 100 / structure.size
          new_pane = _split(current_pane, depth, size)
          _setup_panes(layout_panes, panes_to_init, current_pane, structure.shift, depth+1)
          _setup_panes(layout_panes, panes_to_init, new_pane, structure, depth)
        end
      when Hash
        if structure.values.all? { |v| v.is_a?(Numeric) }
          total_size = structure.values.reduce(:+)
          case structure.size
          when 1
            _setup_panes(layout_panes, panes_to_init, current_pane, structure.keys[0], depth+1)
          else
            size = (total_size - structure.values[0]) * 100 / total_size
            new_pane = _split(current_pane, depth, size)
            first_struct = structure.keys[0]
            structure.delete(first_struct)
            _setup_panes(layout_panes, panes_to_init, current_pane, first_struct, depth+1)
            _setup_panes(layout_panes, panes_to_init, new_pane, structure, depth)
          end
        else
          layout_panes[structure[:name]] = current_pane
          panes_to_init << structure
        end
      when Symbol
        layout_panes[structure] = current_pane
      end
    end

    def _swap_runbook_pane(panes_to_init, layout_panes)
      if (runbook_pane = panes_to_init.find { |pane| pane[:runbook_pane] })
        current_runbook_pane_name = layout_panes.keys.find do |k|
          layout_panes[k] == _runbook_pane
        end
        target_pane_id = layout_panes[runbook_pane[:name]]
        layout_panes[runbook_pane[:name]] = _runbook_pane
        layout_panes[current_runbook_pane_name] = target_pane_id
        _swap_panes(target_pane_id, _runbook_pane)
      end
    end

    def _initialize_panes(panes_to_init, layout_panes)
      panes_to_init.each do |pane|
        target = layout_panes[pane[:name]]
        _set_directory(pane[:directory], target) if pane[:directory]
        send_keys(pane[:command], target) if pane[:command]
      end
    end

    def _runbook_pane
      @runbook_pane ||= `tmux display-message -p '#D'`.strip
    end

    def _rename_window(name)
      `tmux rename-window "#{name}"`
    end

    def _new_window(name)
      `tmux new-window -n "#{name}" -P -F '#D' -d`.strip
    end

    def _split(current_pane, depth, size)
      direction = depth.even? ? "h" : "v"
      command = "tmux split-window"
      args = "-#{direction} -t #{current_pane} -p #{size} -P -F '#D' -d"
      `#{command} #{args}`.strip
    end

    def _swap_panes(target_pane, source_pane)
      `tmux swap-pane -d -t #{target_pane} -s #{source_pane}`
    end

    def _set_directory(directory, target)
      send_keys("cd #{directory}", target)
    end
  end
end
