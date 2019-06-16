module Runbook::Generators
  class Generator < Thor::Group
    include ::Runbook::Generators::Base

    source_root File.dirname(__FILE__)

    def self.usage
      "generator NAME [options]"
    end

    def self.description
      "Generate a runbook generator named NAME, e.x. acme_runbook"
    end

    argument :name, desc: "The name of your generator for populating boilerplate"

    def create_generator_directory
      target = File.join(
        parent_options[:root],
        name.underscore,
      )
      empty_directory(target)
    end

    def create_templates_directory
      target = File.join(
        parent_options[:root],
        name.underscore,
        "templates",
      )
      empty_directory(target)
    end

    def create_generator
      target = File.join(
        parent_options[:root],
        name.underscore,
        "#{name.underscore}.rb",
      )
      template('templates/generator.tt', target)
    end
  end
end
