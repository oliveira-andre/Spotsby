class CreateSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :songs do |t|
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true
      t.references :album, null: false, foreign_key: true
      t.text :lyrics
      t.integer :duartion_ms
      t.integer :age

      t.timestamps
    end
  end
end
