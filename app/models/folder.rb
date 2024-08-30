class Folder < ApplicationRecord
  belongs_to :user
  belongs_to :parent, class_name: 'Folder', optional: true, foreign_key: 'parent_id'
  has_many :subfolders, class_name: 'Folder', foreign_key: 'parent_id', dependent: :destroy
  has_many :media_files, dependent: :destroy

  validates :name, presence: true

  # Метод за генериране на пълния път на папката
  def full_path
    if parent
      File.join(parent.full_path, name)
    else
      name
    end
  end
end
