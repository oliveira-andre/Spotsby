class Album < ApplicationRecord
  acts_as_list scope: :author

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  belongs_to :category
  belongs_to :author

  has_many :songs, -> { ordered }
  scope :ordered, -> { order(position: :asc) }

  validates :name, presence: true, uniqueness: { scope: :author_id }
  validates :release_date, presence: true
  validates :category_id, presence: true
  validates :author_id, presence: true
end
