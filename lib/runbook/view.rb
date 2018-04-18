module Runbook
  module View
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def render(object, output)
        send(_method_name(object), object, output)
      rescue NoMethodError
        $stderr.puts("WARNING! No render rule for #{object.class} (#{_method_name(object)}) in #{self.to_s}")
      end

      def _method_name(object)
        object.class.to_s.underscore.gsub("/", "__")
      end
    end
  end
end
