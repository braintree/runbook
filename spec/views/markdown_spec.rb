require "spec_helper"

RSpec.describe Runbook::Views::Markdown do
  let(:output) { StringIO.new }
  let(:view) { Runbook::Views::Markdown }

  describe "self.render" do
    let(:title) { "This is my title" }

    Runbook.entities.each do |entity|
      it "adds the title to output for entity #{entity}" do
        entity_type = entity.to_s.split("::")[-1].underscore.to_sym
        entity_object = build(entity_type, title: title)
        view.render(entity_object, output)
        expect(output.string).to include(title)
      end
    end

    Runbook.statements.each do |stmt|
      it "generates output for statement #{stmt}" do
        stmt_type = stmt.to_s.split("::")[-1].underscore.to_sym
        stmt_object = build(stmt_type)
        view.render(stmt_object, output)
        expect(output.string).to_not be_empty
      end
    end
  end
end

