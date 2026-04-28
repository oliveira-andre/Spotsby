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

  belongs_to :user

  has_many :playlist_songs, -> { ordered }
  has_many :songs, through: :playlist_songs

  scope :ordered, -> { order(position: :asc) }

  validates :name, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates_numericality_of :position, greater_than_or_equal_to: 0
end
