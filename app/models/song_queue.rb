class SongQueue < ApplicationRecord
  acts_as_list scope: :user

  belongs_to :user
  belongs_to :song

  scope :ordered, -> { order(position: :asc) }

  validates :user_id, presence: true
  validates :song_id, presence: true
  validates_numericality_of :position, greater_than_or_equal_to: 1
end
