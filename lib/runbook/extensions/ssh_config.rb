module Runbook::Extensions
  module SSHConfig
    def self.blank_ssh_config
      {
        servers: [],
        parallelization: {},
      }
    end

    def ssh_config
      @ssh_config ||= Runbook::Extensions::SSHConfig.blank_ssh_config
    end

    module DSL
      def ssh_config(&block)
        config = Class.new do
          attr_reader :dsl
          prepend Runbook::Extensions::SSHConfig
        end.new
        dsl_class = Runbook::DSL.class(
          Runbook::Extensions::SSHConfig::DSL,
        )
        config.instance_variable_set(:@dsl, dsl_class.new(config))
        config.dsl.instance_eval(&block)
        config.ssh_config
      end

      def parallelization(strategy: , limit: 2, wait: 2)
        parent.ssh_config[:parallelization] = {
          strategy: strategy,
          limit: limit,
          wait: wait,
        }
      end

      def server(server)
        parent.ssh_config[:servers].clear
        parent.ssh_config[:servers] << server
      end

      def servers(*servers)
        parent.ssh_config[:servers].clear
        servers.flatten.each do |server|
          parent.ssh_config[:servers] << server
        end
      end

      def path(path)
        parent.ssh_config[:path] = path
      end

      def user(user)
        parent.ssh_config[:user] = user
      end

      def group(group)
        parent.ssh_config[:group] = group
      end

      def env(env)
        parent.ssh_config[:env] = env
      end

      def umask(umask)
        parent.ssh_config[:umask] = umask
      end
    end
  end

  Runbook::Entities::Step.prepend(SSHConfig)
  Runbook::Entities::Step::DSL.prepend(SSHConfig::DSL)
  Runbook::Entities::Section.prepend(SSHConfig)
  Runbook::Entities::Section::DSL.prepend(SSHConfig::DSL)
  Runbook::Entities::Book.prepend(SSHConfig)
  Runbook::Entities::Book::DSL.prepend(SSHConfig::DSL)
end
