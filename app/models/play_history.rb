class PlayHistory < ApplicationRecord
  SOURCE_SEARCH = "search"

  MAX_PER_USER_BY_SOURCE = {
    SOURCE_SEARCH => 20
  }.freeze
  MAX_PER_USER_NIL_SOURCE = 50

  belongs_to :user
  belongs_to :song

  scope :recent, -> { order(created_at: :desc) }
  scope :from_search, -> { where(source: SOURCE_SEARCH) }

  validates :user_id, presence: true
  validates :song_id, presence: true

  def self.cap_for(source)
    MAX_PER_USER_BY_SOURCE[source.to_s] || MAX_PER_USER_NIL_SOURCE
  end
end
