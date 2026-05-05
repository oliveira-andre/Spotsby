# frozen_string_literal: true

class AlbumPolicy < ApplicationPolicy
  def sort_songs?
    author_user_id = record.author.user_id
    author_user_id.present? && author_user_id == user&.id
  end
end
