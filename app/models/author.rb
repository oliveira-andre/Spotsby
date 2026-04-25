class Author < ApplicationRecord
  belongs_to :user, optional: true

  has_many :albums
  has_many :song_authors
  has_many :songs, through: :song_authors

  validates :name, presence: true, uniqueness: true
end
