class Song < ApplicationRecord
  belongs_to :category
  belongs_to :album

  has_many :song_authors
  has_many :authors, through: :song_authors

  has_many :playlist_songs
  has_many :playlists, through: :playlist_songs

  has_many :play_histories
  has_many :users, through: :play_histories

  validates :name, presence: true, uniqueness: true
  validates :category_id, presence: true
  validates :album_id, presence: true
  validates_numericality_of :duration_ms, greater_than_or_equal_to: 0
  validates_numericality_of :age, greater_than_or_equal_to: 0
end
