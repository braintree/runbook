module Runbook::Generators
  module Base
    def self.included(base)
      base.extend(ClassMethods)
      base.include(Thor::Actions)

      set_base_options(base)
      base.check_unknown_options!
    end

    def self.set_base_options(base)
      base.class_option(
        :root,
        group: :base,
        default: ".",
        desc: "The root directory for your generated code",
      )
      base.add_runtime_options!
    end

    module ClassMethods
      def command
        self.to_s.gsub("Runbook::Generators::", "").underscore
      end

      def usage
        "#{command} [options]"
      end

      def description
        "Generate a #{command}"
      end

      def long_description
        description
      end

      def options
        {}
      end
    end
  end
end
