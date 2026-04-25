class CreateAlbums < ActiveRecord::Migration[8.0]
  def change
    create_table :albums do |t|
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true
      t.date :release_date

      t.timestamps
    end
  end
end
