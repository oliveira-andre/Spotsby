class SongQueue < ApplicationRecord
  acts_as_list scope: :user

  belongs_to :user
  belongs_to :song

  scope :ordered, -> { order(position: :asc) }
end
