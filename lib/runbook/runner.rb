module Runbook
  class Runner
    attr_reader :book

    def initialize(book)
      @book = book
    end

    def run(
      run: :ssh_kit,
      noop: false,
      auto: false,
      paranoid: true,
      start_at: "0"
    )
      run = "Runbook::Runs::#{run.to_s.camelize}".constantize
      toolbox = Runbook::Toolbox.new
      metadata = Util::StickyHash.new.merge({
        noop: noop,
        auto: auto,
        paranoid: Util::Glue.new(paranoid),
        start_at: Util::Glue.new(start_at || "0"),
        toolbox: Util::Glue.new(toolbox),
        book_title: book.title,
      }).
      merge(Runbook::Entities::Book.initial_run_metadata).
      merge(additional_metadata)

      stored_pose = _stored_position(metadata)
      if metadata[:start_at] == "0" && stored_pose
        if _resume_previous_pose?(metadata, stored_pose)
          metadata[:start_at] = stored_pose
        end
      end

      if metadata[:start_at] != "0"
        Util::Repo.load(metadata)
      end

      book.run(run, metadata)
    end

    def additional_metadata
      {
        layout_panes: {},
        repo: {},
        reverse: Util::Glue.new(false),
        reversed: Util::Glue.new(false),
      }
    end

    def _stored_position(metadata)
      Runbook::Util::StoredPose.load(metadata)
    end

    def _resume_previous_pose?(metadata, pose)
      return false if metadata[:auto] || metadata[:noop]
      pose_msg = "Previous position detected: #{pose}"
      metadata[:toolbox].output(pose_msg)
      resume_msg = "Do you want to resume at this position?"
      metadata[:toolbox].yes?(resume_msg)
    end
  end
end
