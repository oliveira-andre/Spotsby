require 'rails_helper'

RSpec.describe SongAuthor, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:song_author)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:song) }
    it { is_expected.to belong_to(:author) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:song_id) }
    it { is_expected.to validate_presence_of(:author_id) }
  end
end
