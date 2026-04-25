class SongAuthor < ApplicationRecord
  belongs_to :song
  belongs_to :author

  validates :song_id, presence: true
  validates :author_id, presence: true
end
