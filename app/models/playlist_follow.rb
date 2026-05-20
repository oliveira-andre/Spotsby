class PlaylistFollow < ApplicationRecord
  acts_as_list scope: :user

  belongs_to :user
  belongs_to :playlist

  scope :ordered, -> { order(position: :asc) }

  validates :playlist_id, uniqueness: { scope: :user_id }
  validate :user_cannot_follow_own_playlist

  private

  def user_cannot_follow_own_playlist
    return unless playlist && user_id == playlist.user_id

    errors.add(:user_id, "cannot follow your own playlist")
  end
end
