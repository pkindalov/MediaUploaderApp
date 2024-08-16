# frozen_string_literal: true

module FolderSizeCalculator
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  def calculate_folder_sizes(folders)
    folder_sizes = {}
    folders.each do |folder|
      folder_sizes[folder.id] = calculate_single_folder_size(folder)
    end
    folder_sizes
  end

  def calculate_single_folder_size(folder)
    Rails.cache.fetch("folder_size_#{folder.id}", expires_in: 12.hours) do
      folder.media_files.sum do |media_file|
        file_path = "#{Rails.configuration.user_files_path}/#{folder.user.email}/#{folder.name}/#{media_file.file}"
        File.size(file_path) if File.exist?(file_path)
      end
    end
  end

  def calculate_total_size(folders)
    total_size = folders.sum do |folder|
      calculate_single_folder_size(folder)
    end
    number_to_human_size(total_size)
  end

end
