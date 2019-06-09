require "spec_helper"

RSpec.describe Runbook::Helpers::FormatHelper do
  subject { Class.new { include Runbook::Helpers::FormatHelper }.new }

  describe "deindent" do
    let(:str) do <<-STR
        This message
          has some
        leading whitespace
                    STR
    end
    let(:result) do <<-STR
This message
  has some
leading whitespace
STR
    end

    it "strips redundant leading whitespace from the string" do
      expect(subject.deindent(str)).to eq(result.strip)
    end

    context "when the first line is not the least indented" do
      let(:str) do <<-STR
          This message
        has some
          leading whitespace
                      STR
      end
      let(:result) do <<-STR
    This message
  has some
    leading whitespace
      STR
      end

      it "adds padding in front of each line" do
        expect(subject.deindent(str, padding: 2)).to eq(result.rstrip)
      end

      context "when the second line has no indentation" do
        let(:str) do <<-STR
            This message
has some
            leading whitespace
                        STR
        end
        let(:result) do <<-STR
              This message
  has some
              leading whitespace
        STR
        end

        it "adds padding in front of each line" do
          expect(subject.deindent(str, padding: 2)).to eq(result.rstrip)
        end
      end
    end

    context "when padding is specified" do
      let(:str) do <<-STR
          This message
            has some
          leading whitespace
                      STR
      end
      let(:result) do <<-STR
   This message
     has some
   leading whitespace
      STR
      end

      it "adds padding in front of each line" do
        expect(subject.deindent(str, padding: 3)).to eq(result.rstrip)
      end
    end
  end
end
