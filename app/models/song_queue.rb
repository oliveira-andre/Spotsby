class SongQueue < ApplicationRecord
  acts_as_list scope: :user

  SOURCE_ALBUM = "album"
  SOURCE_POPULAR = "popular"
  SOURCE_ARTIST_SHUFFLE = "artist_shuffle"
  SOURCE_CATEGORY_SHUFFLE = "category_shuffle"
  SOURCE_PLAYLIST = "playlist"
  SOURCE_USER_CUSTOM = "user_custom"
  SOURCE_DEFAULT = "default"
  SOURCES = [ SOURCE_ALBUM, SOURCE_POPULAR, SOURCE_ARTIST_SHUFFLE, SOURCE_CATEGORY_SHUFFLE, SOURCE_PLAYLIST, SOURCE_USER_CUSTOM, SOURCE_DEFAULT ].freeze

  MAX_PER_USER_BY_SOURCE = 100

  belongs_to :user
  belongs_to :song

  scope :ordered, -> { reorder(position: :asc) }
  scope :recent, -> { reorder(created_at: :desc) }

  validates :user_id, presence: true
  validates :song_id, presence: true
  validates :source, inclusion: { in: SOURCES }, allow_nil: true
  validates_numericality_of :position, greater_than_or_equal_to: 1

  def self.cap_for(_source)
    MAX_PER_USER_BY_SOURCE
  end
end
