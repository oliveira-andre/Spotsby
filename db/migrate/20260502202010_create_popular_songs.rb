class CreatePopularSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :popular_songs, id: :uuid do |t|
      t.references :author, null: false, foreign_key: true, type: :uuid
      t.references :song, null: false, foreign_key: true, type: :uuid
      t.integer :position, default: 1

      t.timestamps
    end

    add_index :popular_songs, %i[author_id song_id], unique: true
    add_index :popular_songs, %i[author_id position]
  end
end
