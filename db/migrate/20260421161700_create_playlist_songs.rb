class CreatePlaylistSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :playlist_songs, id: :uuid do |t|
      t.references :playlist, null: false, foreign_key: true, type: :uuid
      t.references :song, null: false, foreign_key: true, type: :uuid
      t.integer :position, default: 1
      t.datetime :added_at

      t.timestamps
    end
  end
end
