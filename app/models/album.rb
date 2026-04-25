class Album < ApplicationRecord
  belongs_to :category
  belongs_to :author

  validates :name, presence: true, uniqueness: true
  validates :release_date, presence: true
  validates :category_id, presence: true
  validates :author_id, presence: true
end
