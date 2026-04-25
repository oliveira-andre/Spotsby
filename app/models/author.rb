class Author < ApplicationRecord
  has_one_attached :image, content_type: %w[image/jpeg image/png image/webp]

  belongs_to :user, optional: true

  has_many :albums
  has_many :song_authors
  has_many :songs, through: :song_authors

  validates :name, presence: true, uniqueness: true
end
