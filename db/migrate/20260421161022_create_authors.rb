class CreateAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :authors do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end
