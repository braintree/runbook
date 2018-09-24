module Runbook
  module Hooks
    def hooks
      @hooks ||= []
    end

    def register_hook(name, type, klass, &block)
      hooks << {
        name: name,
        type: type,
        klass: klass,
        block: block,
      }
    end

    def hooks_for(type, klass)
      hooks.select do |hook|
        hook[:type] == type && klass <= hook[:klass]
      end
    end

    module Invoker
      def invoke_with_hooks(executor, object, *args)
        executor.hooks_for(:before, object.class).each do |hook|
          executor.instance_exec(object, *args, &hook[:block])
        end

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

        executor.hooks_for(:after, object.class).each do |hook|
          executor.instance_exec(object, *args, &hook[:block])
        end
      end
    end
  end
end
