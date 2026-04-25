require 'rails_helper'

RSpec.describe Author, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:author)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:albums) }
    it { is_expected.to have_many(:song_authors) }
    it { is_expected.to have_many(:songs).through(:song_authors) }
  end

  describe 'validations' do
    subject { build(:author) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
