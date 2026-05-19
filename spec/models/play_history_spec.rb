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

  describe 'broadcasting after create' do
    let(:user) { create(:user) }
    let(:session) { create(:session, user: user) }
    let(:song) { create(:song) }

    around do |example|
      Current.set(session: session) { example.run }
    end

    it 'enqueues a Turbo Streams broadcast to the user_play_histories stream' do
      expect {
        PlayHistory.create!(user: user, song: song, played_at: Time.current)
      }.to have_enqueued_job(Turbo::Streams::ActionBroadcastJob)
    end

    it 'broadcasts a turbo_stream that replaces the #player target on every subscribed device' do
      payloads = []
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to).and_wrap_original do |orig, *args, **kwargs|
        payloads << kwargs
        orig.call(*args, **kwargs)
      end

      PlayHistory.create!(user: user, song: song, played_at: Time.current)

      expect(payloads).to include(hash_including(target: "player", partial: "players/player"))
    end

    it 'broadcasts an append targeted at #now-playing-events with the song_event partial' do
      payloads = []
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_later_to).and_wrap_original do |orig, *args, **kwargs|
        payloads << kwargs
        orig.call(*args, **kwargs)
      end

      PlayHistory.create!(user: user, song: song, played_at: Time.current)

      expect(payloads).to include(hash_including(target: "now-playing-events", partial: "players/song_event"))
    end
  end
end
