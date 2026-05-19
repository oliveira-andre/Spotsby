# frozen_string_literal: true

class PlaylistPolicy < ApplicationPolicy
  def show?
    owner? || record.public_status?
  end

  def update_position?
    owner? && record.position.to_i.positive?
  end

  def sort_songs?
    owner?
  end

  def update_name?
    owner?
  end

  def clone?
    user.present? && !owner? && record.public_status?
  end

  private

  def owner?
    record.user_id == user&.id
  end
end
