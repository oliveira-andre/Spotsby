class CreateAlbums < ActiveRecord::Migration[8.0]
  def change
    create_table :albums, id: :uuid do |t|
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :author, null: false, foreign_key: true, type: :uuid
      t.date :release_date

      t.timestamps
    end
  end
end
