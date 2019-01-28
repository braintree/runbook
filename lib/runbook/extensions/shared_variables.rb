module Runbook::Extensions
  module SharedVariables
    module RunHooks
      def self.register_shared_variables_hooks(base)
        base.register_hook(
          :set_ivars_hook,
          :before,
          Runbook::Statement,
        ) do |object, metadata|
          target = SharedVariables::RunHooks._target(object)
          metadata[:repo].each do |key, value|
            target.singleton_class.class_eval { attr_accessor key }
            target.send(SharedVariables::RunHooks._eqls_method(key), value)
          end
        end

        base.register_hook(
          :copy_ivars_to_repo_hook,
          :after,
          Runbook::Statement,
          before: :save_repo_hook
        ) do |object, metadata|
          SharedVariables::RunHooks._copy_ivars_to_repo(object, metadata)
        end
      end

      def self._copy_ivars_to_repo(object, metadata)
        target = _target(object)
        ivars = target.instance_variables - Runbook::DSL.dsl_ivars

        ivars.each do |ivar|
          repo_key = ivar.to_s[1..-1].to_sym
          val = target.instance_variable_get(ivar)
          metadata[:repo][repo_key] = val
        end
      end

      def self._target(object)
        object.parent.dsl
      end

      def self._eqls_method(key)
        "#{key}=".to_sym
      end
    end
  end

  Runbook.runs.each do |run|
    SharedVariables::RunHooks.register_shared_variables_hooks(run)
  end
end
