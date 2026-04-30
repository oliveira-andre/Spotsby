class SongAuthor < ApplicationRecord
  acts_as_list scope: :author

  belongs_to :song
  belongs_to :author

  scope :ordered, -> { order(position: :asc) }

  validates :song_id, presence: true
  validates :author_id, presence: true
end
