class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :authors
  has_many :playlists
  has_many :play_histories
  has_many :song_queues

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
