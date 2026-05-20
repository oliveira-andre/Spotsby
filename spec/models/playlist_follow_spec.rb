require 'rails_helper'

RSpec.describe PlaylistFollow, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      follower = create(:user)
      owner    = create(:user)
      playlist = create(:playlist, user: owner, status: :public)

      expect(build(:playlist_follow, user: follower, playlist: playlist)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:playlist) }
  end

  describe 'validations' do
    it 'forbids the same user from following the same playlist twice' do
      follower = create(:user)
      owner    = create(:user)
      playlist = create(:playlist, user: owner, status: :public)
      create(:playlist_follow, user: follower, playlist: playlist)

      duplicate = build(:playlist_follow, user: follower, playlist: playlist)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:playlist_id]).to be_present
    end

    it 'rejects the playlist owner following their own playlist' do
      owner    = create(:user)
      playlist = create(:playlist, user: owner)

      follow = build(:playlist_follow, user: owner, playlist: playlist)
      expect(follow).not_to be_valid
      expect(follow.errors[:user_id]).to be_present
    end
  end

  describe 'positioning (acts_as_list scope: :user)' do
    it 'assigns sequential positions per user' do
      follower = create(:user)
      a = create(:playlist, user: create(:user), status: :public)
      b = create(:playlist, user: create(:user), status: :public)

      follow_a = create(:playlist_follow, user: follower, playlist: a)
      follow_b = create(:playlist_follow, user: follower, playlist: b)

      expect(follow_a.reload.position).to be < follow_b.reload.position
    end
  end
end
