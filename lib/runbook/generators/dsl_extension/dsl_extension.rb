module Runbook::Generators
  class DslExtension < Thor::Group
    include ::Runbook::Generators::Base

    source_root File.dirname(__FILE__)

    def self.description
      "Generate a dsl_extension for adding custom runbook DSL functionality"
    end

    def self.long_description
      <<-LONG_DESC
      This generator provides a template for extending Runbook's DSL. Using a
      DSL extension, you can add custom commands to a book, section, or step
      that can be used in your runbooks.
      LONG_DESC
    end

    argument :name, desc: "The name of your dsl_extension, e.x. rollback_section"

    def create_dsl_extension
      target = File.join(
        parent_options[:root],
        "#{name.underscore}.rb",
      )
      template('templates/dsl_extension.tt', target)
    end
  end
end
