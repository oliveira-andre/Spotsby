require 'rails_helper'

RSpec.describe Playlist, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:playlist)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:playlist_songs) }
    it { is_expected.to have_many(:songs).through(:playlist_songs) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(private: 0, public: 1).with_suffix }
  end

  describe 'validations' do
    subject { create(:playlist) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:user_id) }

    it 'rejects positions less than 0' do
      playlist = build(:playlist, position: -1)
      expect(playlist).not_to be_valid
    end
  end

  describe '.ordered' do
    it 'returns playlists ordered by position ascending' do
      user = create(:user)
      first = create(:playlist, user: user)
      second = create(:playlist, user: user)
      third = create(:playlist, user: user)

      expect(user.playlists.ordered).to eq([first, second, third])
    end
  end
end
