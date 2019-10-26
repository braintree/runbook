module Factory
  def build(type, overrides={})
    case type
    when :book
      attrs = {
        title: "My Title",
      }.merge!(overrides)
      return Runbook::Entities::Book.new(attrs[:title])
    when :section
      attrs = {
        title: "My Title",
      }.merge!(overrides)
      return Runbook::Entities::Section.new(attrs[:title])
    when :setup
      return Runbook::Entities::Setup.new
    when :step
      attrs = {
        title: "My Title",
      }.merge!(overrides)
      return Runbook::Entities::Step.new(attrs[:title])
    when :ask
      attrs = {
        prompt: "Continue?",
        into: :should_continue,
      }.merge!(overrides)
      return Runbook::Statements::Ask.new(
        attrs[:prompt],
        into: attrs[:into]
      )
    when :assert
      attrs = {
        cmd: "echo 'hi'",
        interval: 1,
        timeout: 5,
        attempts: 3,
        abort_statement: nil,
      }.merge!(overrides)
      return Runbook::Statements::Assert.new(
        attrs[:cmd],
        interval: attrs[:interval],
        timeout: attrs[:timeout],
        attempts: attrs[:attempts],
        abort_statement: attrs[:abort_statement],
      )
    when :capture
      attrs = {
        cmd: "echo 'hi'",
        into: :result,
      }.merge!(overrides)
      return Runbook::Statements::Capture.new(
        attrs[:cmd],
        into: attrs[:into],
      )
    when :capture_all
      attrs = {
        cmd: "echo 'hi'",
        into: :result,
      }.merge!(overrides)
      return Runbook::Statements::CaptureAll.new(
        attrs[:cmd],
        into: attrs[:into],
      )
    when :command
      attrs = {
        cmd: "echo 'hi'",
      }.merge!(overrides)
      return Runbook::Statements::Command.new(
        attrs[:cmd],
      )
    when :condition
      predicate = -> { true }
      if_stmt = -> { }
      attrs = {
        predicate: predicate,
        if_stmt: if_stmt,
        else_stmt: nil,
      }.merge!(overrides)
      return Runbook::Statements::Condition.new(
        predicate: attrs[:predicate],
        if_stmt: attrs[:if_stmt],
        else_stmt: attrs[:else_stmt],
      )
    when :confirm
      attrs = {
        prompt: "Continue?",
      }.merge!(overrides)
      return Runbook::Statements::Confirm.new(
        attrs[:prompt],
      )
    when :description
      attrs = {
        msg: "This is a loooong description",
      }.merge!(overrides)
      return Runbook::Statements::Description.new(
        attrs[:msg],
      )
    when :download
      attrs = {
        from: "/root/my_file.txt",
      }.merge!(overrides)
      return Runbook::Statements::Download.new(
        attrs[:from],
      )
    when :layout
      attrs = {
        structure: [],
      }.merge!(overrides)
      return Runbook::Statements::Layout.new(
        attrs[:structure],
      )
    when :note
      attrs = {
        msg: "fyi",
      }.merge!(overrides)
      return Runbook::Statements::Note.new(
        attrs[:msg],
      )
    when :notice
      attrs = {
        msg: "There be dragons!",
      }.merge!(overrides)
      return Runbook::Statements::Notice.new(
        attrs[:msg],
      )
    when :ruby_command
      cmd = -> { }
      attrs = {
        cmd: cmd,
      }.merge!(overrides)
      return Runbook::Statements::RubyCommand.new(&attrs[:cmd])
    when :tmux_command
      attrs = {
        cmd: "echo 'hi'",
        pane: :pane1,
      }.merge!(overrides)
      return Runbook::Statements::TmuxCommand.new(
        attrs[:cmd],
        attrs[:pane],
      )
    when :upload
      attrs = {
        from: "my_file.txt",
        to: "/root/my_file.txt",
      }.merge!(overrides)
      return Runbook::Statements::Upload.new(
        attrs[:from],
        to: attrs[:to],
      )
    when :wait
      attrs = {
        time: 120,
      }.merge!(overrides)
      return Runbook::Statements::Wait.new(
        attrs[:time],
      )
    else
      raise "No factory found for #{type}!"
    end
  end
end
