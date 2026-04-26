class Category < ApplicationRecord
  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  has_many :albums
  has_many :songs

  validates :name, presence: true, uniqueness: true
end
