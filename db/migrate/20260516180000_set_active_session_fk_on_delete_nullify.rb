class SetActiveSessionFkOnDeleteNullify < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :users, :sessions, column: :active_session_id
    add_foreign_key :users, :sessions, column: :active_session_id, on_delete: :nullify
  end
end
