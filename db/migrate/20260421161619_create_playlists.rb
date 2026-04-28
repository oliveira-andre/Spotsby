class CreatePlaylists < ActiveRecord::Migration[8.0]
  def change
    create_table :playlists, id: :uuid do |t|
      t.string :name, null: false
      t.integer :position, default: 1
      t.integer :status, default: 0
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
