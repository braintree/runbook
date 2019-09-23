module Runbook::Util
  module StoredPose
    FILE_ID = "current_position"
    FILE_PERMISSIONS = 0600

    def self.load(metadata)
      title = metadata[:book_title]
      file = _file(title)
      if File.exists?(file)
        ::YAML::load_file(file)
      end
    end

    def self.save(repo, book_title:)
      File.open(_file(book_title), 'w', FILE_PERMISSIONS) do |f|
        f.write(repo.to_yaml)
      end
    end

    def self.delete(title)
      FileUtils.rm_f(_file(title))
    end

    def self._file(book_title)
      "#{Dir.tmpdir}/runbook_#{FILE_ID}_#{ENV["USER"]}_#{_slug(book_title)}.yml"
    end

    def self._slug(title)
      title.titleize.gsub(/\s+/, "").underscore.dasherize
    end

    def self.register_save_pose_hook(base)
      base.register_hook(
        :save_pose_hook,
        :before,
        Object,
      ) do |object, metadata|
        position = metadata[:position]
        title = metadata[:book_title]
        Runbook::Util::StoredPose.save(position, book_title: title)
      end
    end

    def self.register_delete_stored_pose_hook(base)
      base.register_hook(
        :delete_stored_pose_hook,
        :after,
        Runbook::Entities::Book,
      ) do |object, metadata|
        title = metadata[:book_title]
        Runbook::Util::StoredPose.delete(title)
      end
    end
  end
end
