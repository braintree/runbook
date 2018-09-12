require "spec_helper"

RSpec.describe Runbook::Util::StickyHash do
  let(:sticky_hash) { Runbook::Util::StickyHash.new }
  let(:glue) { Runbook::Util::Glue.new(glue_val) }
  let(:glue_val) { :val }

  it "shares glued state with clones" do
    parent_hash = sticky_hash.merge({a: :b, c: glue})
    clone = parent_hash.dup
    clone[:a] = :e
    clone[:c] = :f
    expect(parent_hash[:a]).to eq(:b)
    expect(parent_hash[:c]).to eq(:f)
  end

  it "shares glued state with merge-created hashes" do
    parent_hash = sticky_hash.merge({a: :b, c: glue})
    merged = parent_hash.merge({something: :else})
    merged[:a] = :e
    merged[:c] = :f
    expect(parent_hash[:a]).to eq(:b)
    expect(parent_hash[:c]).to eq(:f)
  end
end
