class User < ApplicationRecord
  # Visual themes a user can pick on /account. "default" is the palette in
  # DESIGN.md; every other entry has a matching app/assets/stylesheets/themes/
  # file scoped to `body[data-theme="<name>"]`.
  THEMES = %w[default kuromi].freeze

  # Consecutive wrong-password limit before sign-in is locked until a reset.
  LOGIN_MAX_ATTEMPTS = 15

  after_create :create_playlist

  # Setting a new password (the reset link from the lock email, or an admin
  # changing it) lifts a login lock. Deliberately separate from the `blocked`
  # status: a reset must never undo an admin ban or demote an admin.
  before_save :clear_login_lock, if: :will_save_change_to_password_digest?

  validates :theme, inclusion: { in: THEMES }

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
  has_many :playlist_follows, dependent: :destroy
  has_many :followed_playlists, through: :playlist_follows, source: :playlist
  belongs_to :active_session, class_name: "Session", optional: true

  def active_session?(session)
    session && active_session_id == session.id
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def saved_songs_playlist
    playlists.find_by(position: 0)
  end

  def album_playlist(album)
    playlists.find_by(name: album.name)
  end

  def saved_song_ids
    Rails.cache.fetch([ cache_key_with_version, "saved_song_ids" ]) do
      PlaylistSong.where(playlist_id: playlist_ids).distinct.pluck(:song_id)
    end
  end

  def saved_album_names
    Rails.cache.fetch([ cache_key_with_version, "saved_album_names" ]) do
      playlists.pluck(:name)
    end
  end

  def followed_playlist?(playlist)
    return false unless playlist

    playlist_follows.exists?(playlist_id: playlist.id)
  end

  # --- Sign-in lockout ---

  def login_locked?
    locked_at.present?
  end

  def can_sign_in?
    !blocked? && !login_locked?
  end

  # Count a wrong password. The LOGIN_MAX_ATTEMPTS-th locks sign-in and emails
  # a reset link. Banned or already-locked accounts aren't counted, so a banned
  # user never gets an "unlock" email.
  def register_failed_login!
    return if blocked? || login_locked?

    increment!(:failed_login_attempts)
    lock_login! if failed_login_attempts >= LOGIN_MAX_ATTEMPTS
  end

  def reset_failed_logins!
    update_columns(failed_login_attempts: 0) if failed_login_attempts.positive?
  end

  private

  # Conditional on locked_at still being nil so concurrent failures lock (and
  # email) exactly once.
  def lock_login!
    now = Time.current
    return unless self.class.where(id: id, locked_at: nil).update_all(locked_at: now).positive?

    # Mirror the write in memory as already persisted. Left as a pending
    # change from nil, a later save on this same object that clears the lock
    # would see nil -> nil and never write it.
    self.locked_at = now
    clear_attribute_changes([ :locked_at ])
    PasswordsMailer.unlock(self).deliver_later
  end

  def clear_login_lock
    self.failed_login_attempts = 0
    self.locked_at = nil
  end

  def create_playlist
    playlist = Playlist.create!(user: self, name: "Saved Songs", status: :private, position: 0)
    playlist.update_column(:position, 0)
  end
end
