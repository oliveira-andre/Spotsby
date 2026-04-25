class Song < ApplicationRecord
  belongs_to :category
  belongs_to :album

  has_many :song_authors
  has_many :authors, through: :song_authors

  has_many :playlist_songs
  has_many :playlists, through: :playlist_songs

  has_many :play_histories
  has_many :users, through: :play_histories
end
