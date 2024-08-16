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
    folder_path = Rails.env.test? ? "#{Rails.configuration.user_files_path}/tests/#{folder.user.email}/#{folder.name}" : "#{Rails.configuration.user_files_path}/#{folder.user.email}/#{folder.name}"
    Rails.cache.fetch("folder_size_#{folder.id}", expires_in: 12.hours) do
      folder.media_files.sum do |media_file|
        file_path = "#{folder_path}/#{media_file.file}"
        if File.exist?(file_path)
          File.size(file_path)
        else
          0 # Игнориране на невалидни или фиктивни файлове
        end
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
