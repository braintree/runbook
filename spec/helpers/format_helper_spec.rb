require "spec_helper"

RSpec.describe Runbook::Helpers::SSHKitHelper do
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
  end
end
