# frozen_string_literal: true

class PlaylistPolicy < ApplicationPolicy
  def update_position?
    owner? && record.position.to_i.positive?
  end

  def sort_songs?
    owner?
  end

  private

  def owner?
    record.user_id == user&.id
  end
end
