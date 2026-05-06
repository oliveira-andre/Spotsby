class Category < ApplicationRecord
  PRESET_COLORS = %w[#006450 #dc148c #8d67ab #777777 #e61e32 #1e3264].freeze

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
