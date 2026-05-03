class Playlist < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  acts_as_list scope: :user

  enum :status, {
    private: 0,
    public: 1
  }, suffix: true

  belongs_to :user, touch: true

  has_many :playlist_songs, -> { ordered }, dependent: :destroy
  has_many :songs, through: :playlist_songs

  scope :ordered, -> { order(position: :asc) }
  scope :with_songs_count, lambda {
    left_joins(:playlist_songs)
      .select("playlists.*, COUNT(playlist_songs.id) AS songs_count")
      .group("playlists.id")
  }

  validates :name, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates_numericality_of :position, greater_than_or_equal_to: 0
end
