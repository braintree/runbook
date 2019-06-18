module Runbook::Generators
  class Statement < Thor::Group
    include ::Runbook::Generators::Base

    source_root File.dirname(__FILE__)

    def self.description
      "Generate a statement named NAME (e.x. ruby_command) that can be used in your runbooks"
    end

    argument :name, desc: "The name of your statement, e.x. ruby_command"

    def create_statement
      target = File.join(parent_options[:root], "#{name.underscore}.rb")
      template('templates/statement.tt', target)
    end
  end
end
