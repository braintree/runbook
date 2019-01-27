module Runbook::Extensions
  module Global
    module DSL
      def global(*globals)
        Runbook::Statements::Global.new(*globals).tap do |global|
          parent.add(global)
        end
      end

      alias_method :globals, :global
    end

    module RunHooks
      def self.register_globals_hooks(base)
        base.register_hook(
          :define_globals_hook,
          :before,
          Object,
        ) do |object, metadata|
          target = Global::RunHooks._target(object)

          metadata[:globals].each do |global|
            Global::RunHooks._set_ivar(target, global, metadata[:repo])
            Global::RunHooks._set_global_writer(target, global, metadata[:repo])
            Global::RunHooks._set_global_reader(target, global, metadata[:repo])
          end
        end

        base.register_hook(
          :copy_global_ivars_to_repo_hook,
          :after,
          Object,
          before: :save_repo_hook
        ) do |object, metadata|
          Global::RunHooks._copy_ivars_to_repo(object, metadata)
        end
      end

      def self._set_ivar(target, global, repo)
        if repo.has_key?(global)
          target.instance_variable_set(
            _ivar(global),
            repo[global]
          )
        end
      end

      def self._set_global_writer(target, global, repo)
        target.define_singleton_method(_eqls_method(global)) do |value|
          instance_variable_set(Global::RunHooks._ivar(global), value)
          repo[global] = value
        end
      end

      def self._set_global_reader(target, global, repo)
        target.define_singleton_method(global) do
          instance_variable_get(Global::RunHooks._ivar(global)) ||
          repo[global]
        end
      end

      def self._copy_ivars_to_repo(object, metadata)
        target = _target(object)

        metadata[:globals].each do |global|
          ivar = _ivar(global)
          if target.instance_variable_defined?(ivar)
            val = target.instance_variable_get(ivar)
            metadata[:repo][global] = val
          end
        end
      end

      def self._target(object)
        object.parent ? object.parent.dsl : object.dsl
      end

      def self._eqls_method(global)
        "#{global}=".to_sym
      end

      def self._ivar(global)
        "@#{global}".to_sym
      end
    end
  end

  Runbook::Entities::Book::DSL.prepend(Global::DSL)
  Runbook.runs.each do |run|
    Global::RunHooks.register_globals_hooks(run)
  end
end
