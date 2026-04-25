class Category < ApplicationRecord
  has_many :albums
  has_many :songs

  validates :name, presence: true, uniqueness: true
end
