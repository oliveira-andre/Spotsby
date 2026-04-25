class User < ApplicationRecord
  enum :status, {
    active: 0,
    blocked: 1,
    admin: 2
  }

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :authors
  has_many :playlists, -> { ordered }
  has_many :play_histories
  has_many :song_queues, -> { ordered }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
