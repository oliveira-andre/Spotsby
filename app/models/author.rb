class Author < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  belongs_to :user, optional: true

  has_many :albums, -> { ordered }, dependent: :destroy
  has_many :song_authors, -> { ordered }, dependent: :destroy
  has_many :songs, through: :song_authors, dependent: :destroy
  has_many :popular_songs, -> { ordered }, dependent: :destroy
  has_many :top_songs, through: :popular_songs, source: :song

  validates :name, presence: true, uniqueness: true
end
