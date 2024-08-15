# frozen_string_literal: true

class MediaFile < ApplicationRecord
  belongs_to :folder

  validates :file, presence: true, uniqueness: { scope: :folder_id, message: 'Този файл вече съществува в папката.' }
end
