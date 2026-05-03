class User < ApplicationRecord
  after_create :create_playlist

  has_one_attached :avatar
  validates :avatar, content_type: %w[image/png image/jpeg image/gif]

  enum :status, {
    active: 0,
    blocked: 1,
    admin: 2
  }

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :authors, dependent: :nullify
  has_many :playlists, -> { ordered }, dependent: :destroy
  has_many :play_histories, dependent: :destroy
  has_many :song_queues, -> { ordered }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def saved_songs_playlist
    playlists.find_by(position: 0)
  end

  def album_playlist(album)
    playlists.find_by(name: album.name)
  end

  def saved_song_ids
    Rails.cache.fetch([cache_key_with_version, "saved_song_ids"]) do
      PlaylistSong.where(playlist_id: playlist_ids).distinct.pluck(:song_id)
    end
  end

  def saved_album_names
    Rails.cache.fetch([cache_key_with_version, "saved_album_names"]) do
      playlists.pluck(:name)
    end
  end

  private

  def create_playlist
    playlist = Playlist.create!(user: self, name: "Saved Songs", status: :private, position: 0)
    playlist.update_column(:position, 0)
  end
end
