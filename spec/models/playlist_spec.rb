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
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:user_id) }
    it { is_expected.to validate_presence_of(:user_id) }

    it 'rejects positions less than 0' do
      playlist = build(:playlist, position: -1)
      expect(playlist).not_to be_valid
    end
  end

  describe '.ordered' do
    it 'returns playlists ordered by position ascending' do
      user = create(:user)
      saved_songs = user.saved_songs_playlist
      first = create(:playlist, user: user)
      second = create(:playlist, user: user)
      third = create(:playlist, user: user)

      expect(user.playlists.ordered).to eq([ saved_songs, first, second, third ])
    end
  end

  describe '.with_songs_count' do
    it 'attaches a songs_count attribute via the playlist_songs join' do
      playlist = create(:playlist)
      playlist.songs << create(:song)
      playlist.songs << create(:song)

      empty = create(:playlist, user: playlist.user)

      results = Playlist.with_songs_count.where(id: [ playlist.id, empty.id ]).index_by(&:id)
      expect(results[playlist.id].songs_count).to eq(2)
      expect(results[empty.id].songs_count).to eq(0)
    end
  end

  describe 'image validation' do
    it 'rejects an unsupported content type' do
      playlist = create(:playlist)
      playlist.image.attach(io: StringIO.new("x"), filename: "x.txt", content_type: "text/plain")
      expect(playlist).not_to be_valid
      expect(playlist.errors[:image]).to be_present
    end
  end

  describe 'follower associations' do
    it 'destroys playlist_follows when the playlist is destroyed' do
      follower = create(:user)
      owner    = create(:user)
      playlist = create(:playlist, user: owner, status: :public)
      create(:playlist_follow, user: follower, playlist: playlist)

      expect { playlist.destroy }.to change(PlaylistFollow, :count).by(-1)
    end
  end
end
