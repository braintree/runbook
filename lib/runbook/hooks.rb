module Runbook
  module Hooks
    def hooks
      @hooks ||= []
    end

    def register_hook(name, type, klass, before: nil, &block)
      hook = {
        name: name,
        type: type,
        klass: klass,
        block: block,
      }

      if before
        hooks.insert(_hook_index(before), hook)
      else
        hooks << hook
      end
    end

    def hooks_for(type, klass)
      hooks.select do |hook|
        hook[:type] == type && klass <= hook[:klass]
      end
    end

    def _hook_index(hook_name)
      hooks.index { |hook| hook[:name] == hook_name } || -1
    end

    module Invoker
      def invoke_with_hooks(executor, object, *args, &block)
        skip_before = skip_around = skip_after = false
        if executor <= Runbook::Run
          if executor.should_skip?(args[0])
            if executor.start_at_is_substep?(args[0])
              skip_before = skip_around = true
            else
              skip_before = skip_around = skip_after = true
            end
          end
        end

        unless skip_before
          _execute_before_hooks(executor, object, *args)
        end

        if skip_around
          block.call
        else
          _execute_around_hooks(executor, object, *args, &block)
        end

        unless skip_after
          _execute_after_hooks(executor, object, *args)
        end
      end

      def _execute_before_hooks(executor, object, *args)
        executor.hooks_for(:before, object.class).each do |hook|
          executor.instance_exec(object, *args, &hook[:block])
        end
      end

      def _execute_around_hooks(executor, object, *args)
        executor.hooks_for(:around, object.class).reverse.reduce(
          -> (object, *args) {
            yield
          }
        ) do |inner_method, hook|
          -> (object, *args) {
            inner_block = Proc.new do |object, *args|
              inner_method.call(object, *args)
            end
            executor.instance_exec(object, *args, inner_block, &hook[:block])
          }
        end.call(object, *args)
      end

      def _execute_after_hooks(executor, object, *args)
        executor.hooks_for(:after, object.class).each do |hook|
          executor.instance_exec(object, *args, &hook[:block])
        end
      end
    end
  end
end
