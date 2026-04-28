class CreateSongQueues < ActiveRecord::Migration[8.0]
  def change
    create_table :song_queues, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :song, null: false, foreign_key: true, type: :uuid
      t.integer :position, default: 1
      t.string :source

      t.timestamps
    end
  end
end
