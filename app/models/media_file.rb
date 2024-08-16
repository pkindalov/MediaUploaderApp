# frozen_string_literal: true

class MediaFile < ApplicationRecord
  belongs_to :folder

  validates :file, presence: true, uniqueness: { scope: :folder_id, message: 'Този файл вече съществува в папката.' }

  after_save :clear_folder_size_cache
  after_destroy :clear_folder_size_cache

  private

  def clear_folder_size_cache
    Rails.cache.delete("folder_size_#{folder.id}")
  end
end
