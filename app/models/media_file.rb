class MediaFile < ApplicationRecord
  belongs_to :folder
  has_one_attached :file

  validates :file, presence: true
end
