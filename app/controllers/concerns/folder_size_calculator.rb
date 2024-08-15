# frozen_string_literal: true

module FolderSizeCalculator
  extend ActiveSupport::Concern

  def calculate_folder_sizes(folders)
    folder_sizes = {}
    folders.each do |folder|
      folder_size = folder.media_files.sum do |media_file|
        file_path = "#{Rails.configuration.user_files_path}/#{folder.user.email}/#{folder.name}/#{media_file.file}"
        File.size(file_path) if File.exist?(file_path)
      end
      folder_sizes[folder.id] = folder_size
    end
    folder_sizes
  end
end
