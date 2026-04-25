require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:category)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:albums) }
    it { is_expected.to have_many(:songs) }
  end

  describe 'validations' do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
