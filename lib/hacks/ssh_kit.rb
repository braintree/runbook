::SSHKit::Backend::Abstract.class_eval do
  def as(who, &_block)
    if who.is_a? Hash
      @user  = who[:user]  || who["user"]
      @group = who[:group] || who["group"]
    else
      @user  = who
      @group = nil
    end

    execute_args = {verbosity: Logger::DEBUG}
    old_pty = ::SSHKit::Backend::Netssh.config.pty
    begin
      if Runbook.configuration.enable_sudo_prompt
        execute_args[:interaction_handler] ||= ::SSHKit::Sudo::InteractionHandler.new
        ::SSHKit::Backend::Netssh.config.pty = true
      end
      execute <<-EOTEST, execute_args
        if ! sudo -u #{@user} whoami > /dev/null
          then echo "You cannot switch to user '#{@user}' using sudo, please check the sudoers file" 1>&2
          false
        fi
      EOTEST
      yield
    ensure
      ::SSHKit::Backend::Netssh.config.pty = old_pty
    end
  ensure
    remove_instance_variable(:@user)
    remove_instance_variable(:@group)
  end
end
