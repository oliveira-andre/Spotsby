class CreatePlaylistFollows < ActiveRecord::Migration[8.0]
  def change
    create_table :playlist_follows, id: :uuid do |t|
      t.references :user,     null: false, foreign_key: true, type: :uuid
      t.references :playlist, null: false, foreign_key: true, type: :uuid
      t.integer :position, null: false, default: 1

      t.timestamps
    end

    add_index :playlist_follows, [ :user_id, :playlist_id ], unique: true
    add_index :playlist_follows, [ :user_id, :position ]
  end
end
