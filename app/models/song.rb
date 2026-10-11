class Song < ApplicationRecord
  acts_as_list scope: :album

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  has_one_attached :audio
  has_one_attached :audio_fragment

  validates :image, content_type: %w[image/jpeg image/png image/webp]
  validates :audio, content_type: %w[audio/mpeg audio/mp4 audio/ogg audio/vnd.wave], if: :audio_attached?
  validates :audio, size: { less_than: 100.megabytes }
  validates :audio_fragment, content_type: %w[audio/mpeg audio/mp4 audio/ogg audio/vnd.wave], if: :audio_attached?
  validates :audio_fragment, size: { less_than: 100.megabytes }

  belongs_to :category
  belongs_to :album, touch: true

  has_many :song_authors, dependent: :destroy
  has_many :authors, through: :song_authors, dependent: :destroy

  has_many :playlist_songs, dependent: :nullify
  has_many :playlists, through: :playlist_songs, dependent: :destroy

  has_many :play_histories, dependent: :destroy
  has_many :users, through: :play_histories, dependent: :destroy

  has_many :popular_songs, dependent: :destroy

  scope :ordered, -> { order(position: :asc) }

  # Fuzzy search over `search_text` (pg_trgm). `<%` matches when the query is close to
  # some run of words in the text, so partial words and small typos still match; the
  # best matches come first.
  scope :search, ->(q) {
    q = q.to_s.downcase.strip
    where("? <% search_text", q)
      .order(Arel.sql(sanitize_sql_array([ "word_similarity(?, search_text) DESC", q ])))
      .limit(20)
  }

  validates :name, presence: true, uniqueness: { scope: :album_id }
  validates :category_id, presence: true
  validates :album_id, presence: true
  validates_numericality_of :duration_ms, greater_than: 0
  validates_numericality_of :age, greater_than_or_equal_to: 0

  before_validation :inherit_album_image, on: :create
  before_save :build_search_text
  before_update :reject_user_modifications
  after_commit :sync_popular_songs, on: [ :create, :update ], if: :saved_change_to_popular?
  after_commit :enqueue_initial_fragment_job, on: [ :create, :update ]

  private

  # What Song.search matches against: the song, album and author names, lowercased.
  # Album and Author re-save their songs when renamed, and SongAuthor when a song
  # gains or loses an author, so the text follows them.
  def build_search_text
    self.search_text = [ name, album&.name, *author_names ].compact_blank.join(" ").downcase
  end

  # Reads the names without loading `authors` when it isn't loaded yet. Loading it here
  # would cache the list on this object, and a later `author_ids=` on the same object
  # would diff against that stale list and leave old authors behind.
  def author_names
    authors.loaded? ? authors.map(&:name) : authors.pluck(:name)
  end

  def audio_attached?
    audio.attached?
  end

  def reject_user_modifications
    return if Current.user.nil? || Current.user.admin?

    raise ActiveRecord::ReadOnlyRecord, "Song fields cannot be updated by non-admin users"
  end

  def enqueue_initial_fragment_job
    return unless audio.attached?
    return if audio_fragment.attached?

    GenerateInitialFragmentJob.perform_later(id)
  end

  def inherit_album_image
    return if image.attached?
    return unless album&.image&.attached?

    image.attach(album.image.blob)
  end

  def sync_popular_songs
    if popular?
      authors.find_each do |author|
        popular_songs.find_or_create_by!(author: author)
      end
    else
      popular_songs.destroy_all
    end
  end
end
