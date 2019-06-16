module Runbook
  class Generator < Thor
    include Runbook::CLIBase
    include Thor::Actions

    Runbook::Generators::Base.set_base_options(self)

    def self._unique_class_options(generator)
      generator.class_options.values.reject do |class_option|
        class_option.group == "Runtime" ||
          class_option.group == "Base"
      end
    end

    Runbook.generators.each do |generator|
      desc(generator.usage, generator.description, generator.options)

      long_desc(generator.long_description)

      _unique_class_options(generator).each do |co|
        method_option(
          co.name,
          desc: co.description,
          required: co.required,
          default: co.default,
          aliases: co.aliases,
          type: co.type,
          banner: co.banner,
          hide: co.hide,
        )
      end

      define_method(generator.command) do |*args|
        invoke(generator, args)
      end
    end
  end
end
