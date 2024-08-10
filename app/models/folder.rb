class Folder < ApplicationRecord
  belongs_to :user
  has_many :media_files, dependent: :destroy

  validates :name, presence: true
end
