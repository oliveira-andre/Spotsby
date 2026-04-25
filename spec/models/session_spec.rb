require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:session)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end
end
