class Author < ApplicationRecord
  belongs_to :user

  has_many :albums
  has_many :song_authors
  has_many :songs, through: :song_authors
end
