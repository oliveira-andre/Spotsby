class Category < ApplicationRecord
  acts_as_list

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  scope :ordered, -> { order(position: :asc) }

  has_many :albums, -> { ordered }
  has_many :songs, -> { ordered }

  validates :name, presence: true, uniqueness: true
end
