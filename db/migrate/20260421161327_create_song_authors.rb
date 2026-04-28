class CreateSongAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :song_authors, id: :uuid do |t|
      t.references :song, null: false, foreign_key: true, type: :uuid
      t.references :author, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
