class CreatePlayHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :play_histories, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :song, null: false, foreign_key: true, type: :uuid
      t.datetime :played_at

      t.timestamps
    end
  end
end
