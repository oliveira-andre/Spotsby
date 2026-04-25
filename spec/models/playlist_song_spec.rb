require 'rails_helper'

RSpec.describe PlaylistSong, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:playlist_song)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:playlist) }
    it { is_expected.to belong_to(:song) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:playlist_id) }
    it { is_expected.to validate_presence_of(:song_id) }
  end

  describe '.ordered' do
    it 'returns playlist_songs ordered by position ascending' do
      playlist = create(:playlist)
      first = create(:playlist_song, playlist: playlist)
      second = create(:playlist_song, playlist: playlist)
      third = create(:playlist_song, playlist: playlist)

      expect(playlist.playlist_songs.ordered).to eq([first, second, third])
    end
  end
end
