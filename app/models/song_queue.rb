class SongQueue < ApplicationRecord
  acts_as_list scope: :user

  SOURCE_ALBUM = "album"
  SOURCE_POPULAR = "popular"
  SOURCE_ARTIST_SHUFFLE = "artist_shuffle"
  SOURCES = [SOURCE_ALBUM, SOURCE_POPULAR, SOURCE_ARTIST_SHUFFLE].freeze

  belongs_to :user
  belongs_to :song

  scope :ordered, -> { order(position: :asc) }
  scope :recent, -> { order(created_at: :desc) }

  validates :user_id, presence: true
  validates :song_id, presence: true
  validates :source, inclusion: { in: SOURCES }, allow_nil: true
  validates_numericality_of :position, greater_than_or_equal_to: 1
end
