class PopularSong < ApplicationRecord
  acts_as_list scope: :author

  belongs_to :author
  belongs_to :song

  scope :ordered, -> { order(position: :asc) }

  validates :author_id, presence: true
  validates :song_id, presence: true, uniqueness: { scope: :author_id }
end
