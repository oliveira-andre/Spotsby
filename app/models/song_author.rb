class SongAuthor < ApplicationRecord
  acts_as_list scope: :author

  belongs_to :song
  belongs_to :author

  scope :ordered, -> { order(position: :asc) }

  validates :song_id, presence: true
  validates :author_id, presence: true

  # Gaining or losing an author changes the song's search text. The admin forms assign
  # `author_ids` after saving the song, so the song is saved again here. It is loaded
  # fresh so its authors are current, and is gone when the song itself was destroyed.
  after_commit -> { Song.find_by(id: song_id)&.save! }, on: [ :create, :destroy ]
end
