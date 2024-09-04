# frozen_string_literal: true

module FolderSizeCalculator
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  # Calculate the sizes of an array of folders, ensuring no double counting
  def calculate_total_folder_sizes(folders)
    folder_sizes = {}

    folders.each do |folder|
      folder_sizes[folder.id] = calculate_single_folder_size(folder)
    end

    folder_sizes
  end

  # Calculate the total size of a single folder, including only the files directly in it
  def calculate_single_folder_size(folder)
    total_size = 0

    # Calculate the size of files in the current folder
    folder.media_files.each do |media_file|
      file_path = File.join(Rails.configuration.user_files_path, folder.user.email, folder.full_path, media_file.file)
      total_size += File.size(file_path) if File.exist?(file_path)
    end

    total_size
  end

  # Calculate the total size of a collection of folders
  def calculate_total_size(folders)
    total_size = folders.sum do |folder|
      calculate_single_folder_size(folder) + calculate_subfolder_sizes(folder)
    end
    number_to_human_size(total_size)
  end

  # Calculate sizes of subfolders without double counting
  def calculate_subfolder_sizes(folder)
    total_size = 0
    folder.subfolders.each do |subfolder|
      total_size += calculate_single_folder_size(subfolder) + calculate_subfolder_sizes(subfolder)
    end
    total_size
  end

  # Recursive function to add folder and its children
  def add_folder_with_children(folder, folder_list)
    folder_list << folder
    folder.subfolders.order(:created_at).each do |subfolder|
      add_folder_with_children(subfolder, folder_list)
    end
  end
end
