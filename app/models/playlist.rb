class Playlist < ApplicationRecord
  acts_as_list scope: :user

  enum status: {
    private: 0,
    public: 1
  }

  belongs_to :user

  has_many :playlist_songs, -> { ordered }
  has_many :songs, through: :playlist_songs

  scope :ordered, -> { order(position: :asc) }
end
