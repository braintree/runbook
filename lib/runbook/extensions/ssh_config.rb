module Runbook::Extensions
  module SSHConfig
    def ssh_config
      @ssh_config ||= {
        servers: []
      }
    end

    def parallelization(strategy: , limit: 2, wait: 2)
      ssh_config[:parallelization] = {
        strategy: strategy,
        limit: limit,
        wait: wait,
      }
    end

    def server(server)
      ssh_config[:servers].clear
      ssh_config[:servers] << server
    end

    def servers(*servers)
      ssh_config[:servers].clear
      servers.each { |server| ssh_config[:servers] << server }
    end

    def path(path)
      ssh_config[:path] = path
    end

    def user(user)
      ssh_config[:user] = user
    end

    def group(group)
      ssh_config[:group] = group
    end

    def env(env)
      ssh_config[:env] = env
    end

    def umask(umask)
      ssh_config[:umask] = umask
    end
  end

  Runbook::Entities::Step.prepend(SSHConfig)
end
