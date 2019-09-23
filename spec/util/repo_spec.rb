require "spec_helper"

RSpec.describe Runbook::Util::Repo, type: :aruba do
  let(:toolbox) { Runbook::Toolbox.new }
  let(:book_title) { "My Amazing Runbook" }
  let(:repo) { {some: :thing} }
  let(:metadata) {
    Runbook::Util::StickyHash.new.merge({
      toolbox: toolbox,
      book_title: book_title,
      repo: Runbook::Util::Glue.new(repo),
    })
  }
  let(:file) {
    Runbook::Util::Repo._file(book_title)
  }
  let(:file_content) {
    repo.to_yaml
  }

  before(:each) do
    allow(toolbox).to receive(:output)
  end

  after(:each) do
    FileUtils.rm_f(file)
  end

  describe "self.load_repo" do
    context "when file does not exist" do
      it "does not set the repo" do
        expect(::YAML).to_not receive(:load_file)

        Runbook::Util::Repo.load(metadata)
      end
    end

    context "when repo_file exists" do
      before(:each) { write_file(file, file_content) }

      it "outputs that it is loading the file" do
        expect(toolbox).to receive(:output).with(
          /Loading previous state/
        )

        Runbook::Util::Repo.load(metadata)
      end

      it "sets the repo" do
        metadata[:repo] = {}

        Runbook::Util::Repo.load(metadata)

        expect(metadata[:repo]).to eq(repo)
      end
    end
  end

  describe "self.save_repo" do
    let(:repo) { {flower: "daisy"} }

    it "saves the repo" do
      Runbook::Util::Repo.save(repo, book_title: book_title)
      metadata[:repo] = {}

      Runbook::Util::Repo.load(metadata)
      expect(metadata[:repo]).to eq(repo)
    end

    context "when the title has invalid characters" do
      let(:book_title) { "My/Amazing/Runbook" }

      it "saves the repo" do
        Runbook::Util::Repo.save(repo, book_title: book_title)
        metadata[:repo] = {}

        Runbook::Util::Repo.load(metadata)
        expect(metadata[:repo]).to eq(repo)
      end
    end
  end

  describe "self.delete" do
    it "deletes the stored repo" do
      Runbook::Util::Repo.save(repo, book_title: book_title)

      Runbook::Util::Repo.delete(book_title)

      expect(file).to_not be_an_existing_file
    end
  end
end
