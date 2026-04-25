require 'rails_helper'

RSpec.describe SongQueue, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:song_queue)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:song) }
  end

  describe 'validations' do
    subject { create(:song_queue) }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:song_id) }

    it 'rejects positions less than 1' do
      song_queue = build(:song_queue, position: 0)
      expect(song_queue).not_to be_valid
    end
  end

  describe '.ordered' do
    it 'returns song_queues ordered by position ascending' do
      user = create(:user)
      first = create(:song_queue, user: user)
      second = create(:song_queue, user: user)
      third = create(:song_queue, user: user)

      expect(user.song_queues.ordered).to eq([first, second, third])
    end
  end
end
