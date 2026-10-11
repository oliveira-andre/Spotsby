class Author < ApplicationRecord
  include NameSearch

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  belongs_to :user, optional: true

  has_many :albums, -> { ordered }, dependent: :destroy
  has_many :song_authors, -> { ordered }, dependent: :destroy
  has_many :songs, through: :song_authors, dependent: :destroy
  has_many :popular_songs, -> { ordered }, dependent: :destroy
  has_many :top_songs, through: :popular_songs, source: :song

  validates :name, presence: true, uniqueness: true

  # Its songs' search text includes the author name. `after_update`, not
  # `after_update_commit`: a touch (from its albums) also runs commit callbacks, and a
  # freshly created author still reports its name as changed then.
  after_update -> { songs.reorder(nil).find_each(&:save!) }, if: :saved_change_to_name?
end
