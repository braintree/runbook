module Runbook
  module View
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def render(object, output, metadata)
        method = _method_name(object)
        if respond_to?(method)
          send(_method_name(object), object, output, metadata)
        else
          $stderr.puts("WARNING! No render rule for #{object.class} (#{_method_name(object)}) in #{self.to_s}")
        end
      end

      def _method_name(object)
        object.class.to_s.underscore.gsub("/", "__")
      end
    end
  end
end
