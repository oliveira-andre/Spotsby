class CreateAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :authors, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :slug, null: false
      t.references :user, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :authors, :slug, unique: true
  end
end
