class CreateSongAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :song_authors do |t|
      t.references :song, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true

      t.timestamps
    end
  end
end
