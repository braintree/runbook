require "spec_helper"

RSpec.describe Runbook::Util::StoredPose, type: :aruba do
  let(:toolbox) { Runbook::Toolbox.new }
  let(:book_title) { "My Amazing Runbook" }
  let(:current_pose) { "1.1" }
  let(:metadata) {
    Runbook::Util::StickyHash.new.merge({
      toolbox: toolbox,
      book_title: book_title,
      position: current_pose,
    })
  }
  let(:file) {
    Runbook::Util::StoredPose._file(book_title)
  }
  let(:file_content) {
    current_pose.to_yaml
  }

  after(:each) do
    FileUtils.rm_f(file)
  end

  describe "self.load_repo" do
    context "when file does not exist" do
      it "does not set the repo" do
        expect(::YAML).to_not receive(:load_file)

        Runbook::Util::Repo.load(metadata)
      end

      it "returns nil" do
        expect(Runbook::Util::Repo.load(metadata)).to be_nil
      end
    end

    context "when repo_file exists" do
      let(:current_pose) { "1.1.1.1.1" }

      before(:each) { write_file(file, file_content) }

      it "returns the current_pose" do
        pose = Runbook::Util::StoredPose.load(metadata)

        expect(pose).to eq(current_pose)
      end
    end
  end

  describe "self.save_repo" do
    let(:current_pose) { "2" }

    it "saves the current position" do
      Runbook::Util::StoredPose.save(current_pose, book_title: book_title)

      pose = Runbook::Util::StoredPose.load(metadata)
      expect(pose).to eq(current_pose)
    end
  end

  describe "self.delete" do
    it "deletes the stored repo" do
      Runbook::Util::StoredPose.save(current_pose, book_title: book_title)

      Runbook::Util::StoredPose.delete(book_title)

      expect(file).to_not be_an_existing_file
    end
  end
end
