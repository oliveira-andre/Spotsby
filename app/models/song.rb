class Song < ApplicationRecord
  acts_as_list scope: :album

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  has_one_attached :audio

  validates :image, content_type: %w[image/jpeg image/png image/webp]
  validates :audio, content_type: %w[audio/mpeg audio/mp4 audio/ogg audio/vnd.wave], if: :audio_attached?
  validates :audio, size: { less_than: 100.megabytes }

  belongs_to :category
  belongs_to :album

  has_many :song_authors
  has_many :authors, through: :song_authors

  has_many :playlist_songs
  has_many :playlists, through: :playlist_songs

  has_many :play_histories
  has_many :users, through: :play_histories

  has_many :popular_songs, dependent: :destroy

  scope :ordered, -> { order(position: :asc) }

  validates :name, presence: true, uniqueness: { scope: :album_id }
  validates :category_id, presence: true
  validates :album_id, presence: true
  validates_numericality_of :duration_ms, greater_than_or_equal_to: 0
  validates_numericality_of :age, greater_than_or_equal_to: 0

  private

  def audio_attached?
    audio.attached?
  end
end
