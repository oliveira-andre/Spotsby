require 'rails_helper'

RSpec.describe Song, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:song)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:album) }
    it { is_expected.to have_many(:song_authors) }
    it { is_expected.to have_many(:authors).through(:song_authors) }
    it { is_expected.to have_many(:playlist_songs) }
    it { is_expected.to have_many(:playlists).through(:playlist_songs) }
    it { is_expected.to have_many(:play_histories) }
    it { is_expected.to have_many(:users).through(:play_histories) }
  end

  describe 'validations' do
    subject { create(:song) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:category_id) }
    it { is_expected.to validate_presence_of(:album_id) }
    it { is_expected.to validate_numericality_of(:duration_ms).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:age).is_greater_than_or_equal_to(0) }
  end
end
