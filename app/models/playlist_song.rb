class PlaylistSong < ApplicationRecord
  acts_as_list scope: :playlist

  belongs_to :playlist
  belongs_to :song

  scope :ordered, -> { order(position: :asc) }
end
