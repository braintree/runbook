module Runbook
  class Step
    attr_reader :title

    def initialize(title)
      @title = title
    end

    module ServerList
      def server_list
        @server_list ||= []
      end

      def server(server)
        server_list.clear
        server_list << server
      end

      def servers(servers)
        server_list.clear
        servers.each { |server| server_list << server }
      end
    end
    prepend ServerList

    module Statements
      def statements
        @statements ||= []
      end

      def method_missing(name, *args, &block)
        if (klass = Statements._statement_class(name))
          klass.new(*args, &block).tap do |statement|
            statements << statement
          end
        else
          super
        end
      end

      def respond_to?(name, include_private = false)
        !!(Statements._statement_class(name) || super)
      end

      def self._statement_class(name)
        "Runbook::Statements::#{name.to_s.camelize}".constantize
      rescue NameError
      end
    end
    prepend Statements
  end
end
