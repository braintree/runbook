module Runbook::Generators
  class Runbook < Thor::Group
    include ::Runbook::Generators::Base

    source_root File.dirname(__FILE__)

    def self.usage
      "runbook NAME [options]"
    end

    def self.description
      "Generate a runbook named NAME, e.x. deploy_nginx"
    end

    argument :name, desc: "The name of your runbook, e.x. deploy_nginx"

    def create_runbook
      target = File.join(options[:root], "#{name.underscore}.rb")
      template('templates/runbook.tt', target)
    end
  end
end
