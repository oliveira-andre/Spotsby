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

  after_create_commit :broadcast_now_playing

  def self.cap_for(source)
    MAX_PER_USER_BY_SOURCE[source.to_s] || MAX_PER_USER_NIL_SOURCE
  end

  private

  def broadcast_now_playing
    broadcast_append_later_to user, "play_histories",
      target: "now-playing-events",
      partial: "players/song_event",
      locals: { song: song }
  end
end
