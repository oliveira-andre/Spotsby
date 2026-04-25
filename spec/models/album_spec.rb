require 'rails_helper'

RSpec.describe Album, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:album)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:author) }
  end

  describe 'validations' do
    subject { create(:album) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:release_date) }
    it { is_expected.to validate_presence_of(:category_id) }
    it { is_expected.to validate_presence_of(:author_id) }
  end
end
