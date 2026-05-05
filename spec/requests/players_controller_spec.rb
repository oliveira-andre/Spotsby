require 'rails_helper'

RSpec.describe PlayersController, type: :request do
  let(:user) { create(:user) }
  let(:author) { create(:author) }
  let(:album) { create(:album, author: author) }
  let(:song) { create(:song, album: album, position: 1) }

  before { sign_in(user) }

  describe 'GET /players/:id' do
    it 'records a queue entry and a play history' do
      expect {
        get player_path(song)
      }.to change { user.song_queues.count }.by(1)
       .and change { user.play_histories.count }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it 'normalizes an unknown source to default' do
      get player_path(song, source: 'made-up')
      expect(user.song_queues.last.source).to eq(SongQueue::SOURCE_DEFAULT)
    end

    it 'persists a known source' do
      get player_path(song, source: SongQueue::SOURCE_ALBUM)
      expect(user.song_queues.last.source).to eq(SongQueue::SOURCE_ALBUM)
    end

    it 'still renders when the song does not exist' do
      get player_path('does-not-exist')
      expect(response).to have_http_status(:ok)
      expect(user.song_queues.count).to eq(0)
    end
  end

  describe 'POST /players/next' do
    it 'redirects back when no current queue entry exists' do
      post next_players_path
      expect(response).to redirect_to(root_path)
    end

    it 'advances to the next album track when source is album' do
      next_song = create(:song, album: album, position: 2)
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_ALBUM)

      expect {
        post next_players_path
      }.to change { user.song_queues.count }.by(1)

      expect(response).to redirect_to(player_path(next_song))
      expect(user.song_queues.recent.first.source).to eq(SongQueue::SOURCE_ALBUM)
    end

    it 'falls back to artist shuffle when no album sibling exists' do
      sibling = create(:song, album: album, position: 5)
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_DEFAULT)

      post next_players_path

      shuffle_entry = user.song_queues.where(source: SongQueue::SOURCE_ARTIST_SHUFFLE).first
      expect(shuffle_entry).to be_present
      expect(shuffle_entry.song).to eq(sibling)
    end
  end

  describe 'POST /players/previous' do
    it 'goes to the previous album track when one exists' do
      first_song = song
      second_song = create(:song, album: album, position: 2)
      create(:song_queue, user: user, song: second_song, source: SongQueue::SOURCE_ALBUM)

      post previous_players_path

      expect(response).to redirect_to(player_path(first_song))
    end

    it 'redirects back to the current song when there is no previous track' do
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_ALBUM)

      post previous_players_path
      expect(response).to redirect_to(player_path(song))
    end
  end
end
