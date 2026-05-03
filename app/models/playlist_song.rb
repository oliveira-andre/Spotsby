class PlaylistSong < ApplicationRecord
  acts_as_list scope: :playlist

  belongs_to :playlist, touch: true
  belongs_to :song

  scope :ordered, -> { order(position: :asc) }

  validates :playlist_id, presence: true
  validates :song_id, presence: true
end
