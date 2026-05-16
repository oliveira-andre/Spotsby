class AddNowPlayingTrackingToUsersAndSessions < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :active_session, type: :uuid, foreign_key: { to_table: :sessions }, null: true
    add_column :sessions, :last_seen_at, :datetime
    add_index :sessions, [ :user_id, :last_seen_at ]
  end
end
