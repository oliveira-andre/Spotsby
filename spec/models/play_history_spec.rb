require 'rails_helper'

RSpec.describe PlayHistory, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:play_history)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:song) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:song_id) }
  end
end
