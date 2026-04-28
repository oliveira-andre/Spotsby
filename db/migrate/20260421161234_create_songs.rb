class CreateSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :songs, id: :uuid do |t|
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :album, null: false, foreign_key: true, type: :uuid
      t.text :lyrics
      t.integer :duration_ms
      t.integer :age

      t.timestamps
    end
  end
end
