# frozen_string_literal: true

module FileSorting
  extend ActiveSupport::Concern

  def sort_files_by_availability(files)
    files.sort_by do |media_file|
      file_path = File.join(Rails.configuration.user_files_path, media_file.folder.user.email, media_file.folder.name, media_file.file)
      File.exist?(file_path) ? 0 : 1
    end
  end
end
