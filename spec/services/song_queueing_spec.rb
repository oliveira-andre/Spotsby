require 'rails_helper'

RSpec.describe SongQueueing do
  let(:user) { create(:user) }
  let(:song) { create(:song) }
  let(:other_song) { create(:song) }
  let(:third_song) { create(:song) }
  subject(:service) { described_class.new(user) }

  describe '#enqueue' do
    context 'when there is no play history' do
      it 'creates a pending user_custom entry' do
        expect {
          service.enqueue(song)
        }.to change { user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM).count }.by(1)

        entry = user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM).first
        expect(entry.song).to eq(song)
      end
    end

    context 'when the most recent play history is not user_custom' do
      before do
        create(:play_history, user: user, song: other_song, source: SongQueue::SOURCE_ALBUM, played_at: 1.minute.ago)
      end

      it 'wipes any prior pending user_custom entries before inserting' do
        create(:song_queue, user: user, song: third_song, source: SongQueue::SOURCE_USER_CUSTOM)
        create(:song_queue, user: user, song: other_song, source: SongQueue::SOURCE_USER_CUSTOM)

        service.enqueue(song)

        custom = user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM)
        expect(custom.count).to eq(1)
        expect(custom.first.song).to eq(song)
      end

      it 'leaves other-source song queue entries untouched' do
        create(:song_queue, user: user, song: third_song, source: SongQueue::SOURCE_ALBUM)

        service.enqueue(song)

        expect(user.song_queues.where(source: SongQueue::SOURCE_ALBUM).count).to eq(1)
      end
    end

    context 'when the most recent play history is user_custom' do
      before do
        create(:play_history, user: user, song: other_song, source: SongQueue::SOURCE_ALBUM, played_at: 2.minutes.ago)
        create(:play_history, user: user, song: third_song, source: SongQueue::SOURCE_USER_CUSTOM, played_at: 1.minute.ago)
      end

      it 'appends to the existing pending queue without wiping' do
        existing = create(:song_queue, user: user, song: third_song, source: SongQueue::SOURCE_USER_CUSTOM)

        service.enqueue(song)

        custom = user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM).order(:created_at)
        expect(custom.count).to eq(2)
        expect(custom.first).to eq(existing)
        expect(custom.last.song).to eq(song)
      end
    end

    context 'pruning to the per-source cap' do
      it 'keeps the newest entries and trims the oldest beyond the cap' do
        stub_const("SongQueue::MAX_PER_USER_BY_SOURCE", 3)
        # Force the "in custom queue" path so we just append
        create(:play_history, user: user, song: other_song, source: SongQueue::SOURCE_USER_CUSTOM, played_at: 1.minute.ago)
        oldest = create(:song_queue, user: user, song: third_song, source: SongQueue::SOURCE_USER_CUSTOM)
        oldest.update_column(:created_at, 1.hour.ago)
        second = create(:song_queue, user: user, song: other_song, source: SongQueue::SOURCE_USER_CUSTOM)
        second.update_column(:created_at, 30.minutes.ago)
        third = create(:song_queue, user: user, song: third_song, source: SongQueue::SOURCE_USER_CUSTOM)
        third.update_column(:created_at, 10.minutes.ago)

        service.enqueue(song)

        custom = user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM)
        expect(custom.count).to eq(3)
        expect(custom.pluck(:id)).not_to include(oldest.id)
      end
    end
  end
end
