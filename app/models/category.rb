class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  has_many :albums, -> { ordered }
  has_many :songs, -> { ordered }

  validates :name, presence: true, uniqueness: true
end
