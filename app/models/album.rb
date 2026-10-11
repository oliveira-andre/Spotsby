class Album < ApplicationRecord
  include NameSearch

  acts_as_list scope: :author

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one_attached :image
  validates :image, content_type: %w[image/jpeg image/png image/webp]

  belongs_to :category
  belongs_to :author, touch: true

  has_many :songs, -> { ordered }, dependent: :destroy
  scope :ordered, -> { order(position: :asc) }

  validates :name, presence: true, uniqueness: { scope: :author_id }
  validates :release_date, presence: true
  validates :category_id, presence: true
  validates :author_id, presence: true

  # Its songs' search text includes the album name. `after_update`, not
  # `after_update_commit`: a touch (a song saving, an attachment) also runs commit
  # callbacks, and a freshly created album still reports its name as changed then.
  after_update -> { songs.reorder(nil).find_each(&:save!) }, if: :saved_change_to_name?
end
