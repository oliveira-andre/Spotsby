# frozen_string_literal: true

class AuthorPolicy < ApplicationPolicy
  def sort_popular_songs?
    return false unless user

    user.admin? || (record.user_id.present? && record.user_id == user.id)
  end
end
