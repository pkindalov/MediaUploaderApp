class CreateMediaFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :media_files do |t|
      t.string :file
      t.references :folder, null: false, foreign_key: true

      t.timestamps
    end
  end
end
