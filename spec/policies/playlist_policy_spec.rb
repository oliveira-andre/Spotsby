require 'rails_helper'

RSpec.describe PlaylistPolicy do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }

  describe '#show?' do
    it 'allows the owner regardless of status' do
      playlist = create(:playlist, user: owner, status: :private)
      expect(described_class.new(owner, playlist).show?).to be(true)
    end

    it 'allows a non-owner when the playlist is public' do
      playlist = create(:playlist, user: owner, status: :public)
      expect(described_class.new(other, playlist).show?).to be(true)
    end

    it 'denies a non-owner when the playlist is private' do
      playlist = create(:playlist, user: owner, status: :private)
      expect(described_class.new(other, playlist).show?).to be(false)
    end
  end

  describe '#update_position?' do
    it 'allows the owner on a positively positioned playlist' do
      playlist = create(:playlist, user: owner)
      expect(playlist.position).to be > 0
      expect(described_class.new(owner, playlist).update_position?).to be(true)
    end

    it 'denies the owner on the pinned position-0 playlist' do
      saved = owner.saved_songs_playlist
      expect(described_class.new(owner, saved).update_position?).to be(false)
    end

    it 'denies a non-owner' do
      playlist = create(:playlist, user: owner)
      expect(described_class.new(other, playlist).update_position?).to be(false)
    end
  end

  describe '#sort_songs?' do
    it 'allows the owner' do
      playlist = create(:playlist, user: owner)
      expect(described_class.new(owner, playlist).sort_songs?).to be(true)
    end

    it 'denies a non-owner' do
      playlist = create(:playlist, user: owner)
      expect(described_class.new(other, playlist).sort_songs?).to be(false)
    end
  end

  describe '#update_name?' do
    it 'allows the owner' do
      playlist = create(:playlist, user: owner)
      expect(described_class.new(owner, playlist).update_name?).to be(true)
    end

    it 'denies a non-owner' do
      playlist = create(:playlist, user: owner)
      expect(described_class.new(other, playlist).update_name?).to be(false)
    end
  end

  describe '#clone?' do
    it 'allows a signed-in non-owner of a public playlist' do
      playlist = create(:playlist, user: owner, status: :public)
      expect(described_class.new(other, playlist).clone?).to be(true)
    end

    it 'denies the owner from cloning their own playlist' do
      playlist = create(:playlist, user: owner, status: :public)
      expect(described_class.new(owner, playlist).clone?).to be(false)
    end

    it 'denies cloning a private playlist' do
      playlist = create(:playlist, user: owner, status: :private)
      expect(described_class.new(other, playlist).clone?).to be(false)
    end

    it 'denies an anonymous (nil) user' do
      playlist = create(:playlist, user: owner, status: :public)
      expect(described_class.new(nil, playlist).clone?).to be(false)
    end
  end

  describe '#follow?' do
    it 'allows a signed-in non-owner of a public playlist' do
      playlist = create(:playlist, user: owner, status: :public)
      expect(described_class.new(other, playlist).follow?).to be(true)
    end

    it 'denies the owner from following their own playlist' do
      playlist = create(:playlist, user: owner, status: :public)
      expect(described_class.new(owner, playlist).follow?).to be(false)
    end

    it 'denies following a private playlist' do
      playlist = create(:playlist, user: owner, status: :private)
      expect(described_class.new(other, playlist).follow?).to be(false)
    end

    it 'denies an anonymous (nil) user' do
      playlist = create(:playlist, user: owner, status: :public)
      expect(described_class.new(nil, playlist).follow?).to be(false)
    end
  end
end
