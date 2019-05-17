::SSHKit::Backend::Abstract.class_eval do
  # Code taken from https://github.com/capistrano/sshkit/blob/v1.16.0/lib/sshkit/backends/abstract.rb#L98-L116
  # Copyright (c) 2008- Lee Hambley & Contributors
  # License link: https://github.com/capistrano/sshkit/blob/v1.16.0/LICENSE.md
  #
  # Full copyright notice and license:
  #
  # Copyright (c) 2008- Lee Hambley & Contributors
  #
  # Permission is hereby granted, free of charge, to any person obtaining a
  # copy of this software and associated documentation files (the "Software"),
  # to deal in the Software without restriction, including without limitation
  # the rights to use, copy, modify, merge, publish, distribute, sublicense,
  # and/or sell copies of the Software, and to permit persons to whom the
  # Software is furnished to do so, subject to the following conditions:
  #
  # The above copyright notice and this permission notice shall be included
  # in all copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  # FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  # DEALINGS IN THE SOFTWARE.

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
