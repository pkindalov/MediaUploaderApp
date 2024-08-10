class MediaFile < ApplicationRecord
  belongs_to :folder

  validates :file, presence: true
end
