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

    it 'makes the visiting device the active playback session' do
      # A second device is currently the active one.
      other = user.sessions.create!(user_agent: "Other", ip_address: "1.2.3.4")
      user.update!(active_session_id: other.id)

      get player_path(song)

      # Visiting the player claims playback for this request's session, not the old one.
      expect(user.reload.active_session_id).to eq(user.sessions.order(:created_at).first.id)
      expect(user.active_session_id).not_to eq(other.id)
    end

    it 'de-duplicates search history so a replayed song appears once, most recent first' do
      other_song = create(:song, album: album, position: 2)

      get player_path(song, source: PlayHistory::SOURCE_SEARCH)
      get player_path(other_song, source: PlayHistory::SOURCE_SEARCH)
      get player_path(song, source: PlayHistory::SOURCE_SEARCH)

      searches = user.play_histories.from_search
      expect(searches.where(song_id: song.id).count).to eq(1)
      expect(searches.recent.map(&:song_id)).to eq([ song.id, other_song.id ])
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

  describe 'POST /players/next with a turbo_stream accept header' do
    let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it 'renders a turbo_stream response instead of redirecting' do
      next_song = create(:song, album: album, position: 2)
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_ALBUM)

      post next_players_path, headers: turbo_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include(next_song.slug)
    end

    it 'still records the play history and queue entry' do
      create(:song, album: album, position: 2)
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_ALBUM)

      expect {
        post next_players_path, headers: turbo_headers
      }.to change { user.song_queues.count }.by(1)
       .and change { user.play_histories.count }.by(1)
    end

    it 'returns no_content when no current song is queued' do
      post next_players_path, headers: turbo_headers
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'POST /players/toggle_random' do
    it 'flips the random_mode flag and renders a turbo stream' do
      expect {
        post toggle_random_players_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change { user.reload.random_mode }.from(false).to(true)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("player_random_toggle")
    end
  end

  describe 'POST /players/next when random_mode is on' do
    it 'picks a random song from the current song category instead of an album sibling' do
      user.update!(random_mode: true)
      same_category_song = create(:song, album: album, position: 2, category: song.category)
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_ALBUM)

      post next_players_path

      latest = user.song_queues.unscope(:order).order(created_at: :desc).first
      expect(latest.source).to eq(SongQueue::SOURCE_CATEGORY_SHUFFLE)
      expect(latest.song).to eq(same_category_song)
    end

    it 'falls through to normal advancement when no other category song exists' do
      user.update!(random_mode: true)
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_ALBUM)
      next_song = create(:song, album: album, position: 2)

      post next_players_path

      latest = user.song_queues.unscope(:order).order(created_at: :desc).first
      expect(latest.source).to eq(SongQueue::SOURCE_ALBUM)
      expect(latest.song).to eq(next_song)
    end
  end

  describe 'POST /players/next with a pending user_custom queue' do
    it 'pops the queued song even when currently playing from a non-user_custom source' do
      queued_song = create(:song)
      create(:song, album: album, position: 2)
      create(:play_history, user: user, song: song, source: SongQueue::SOURCE_ALBUM, played_at: 1.minute.ago)
      create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_ALBUM)
      create(:song_queue, user: user, song: queued_song, source: SongQueue::SOURCE_USER_CUSTOM)

      post next_players_path

      expect(user.play_histories.recent.first.song).to eq(queued_song)
      expect(user.play_histories.recent.first.source).to eq(SongQueue::SOURCE_USER_CUSTOM)
      expect(user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM)).to be_empty
    end
  end

  describe 'POST /players/next when the current source is user_custom' do
    let(:queued_song) { create(:song) }
    let(:later_song) { create(:song) }

    it 'pops the oldest pending user_custom entry and plays it' do
      create(:play_history, user: user, song: song, source: SongQueue::SOURCE_USER_CUSTOM, played_at: 1.minute.ago)
      pending = create(:song_queue, user: user, song: queued_song, source: SongQueue::SOURCE_USER_CUSTOM)

      expect {
        post next_players_path
      }.to change { user.song_queues.where(id: pending.id).count }.from(1).to(0)
       .and change { user.play_histories.count }.by(1)

      expect(user.play_histories.recent.first.song).to eq(queued_song)
      expect(user.play_histories.recent.first.source).to eq(SongQueue::SOURCE_USER_CUSTOM)
    end

    it 'plays user_custom entries in created_at order' do
      create(:play_history, user: user, song: song, source: SongQueue::SOURCE_USER_CUSTOM, played_at: 1.minute.ago)
      older = create(:song_queue, user: user, song: queued_song, source: SongQueue::SOURCE_USER_CUSTOM, created_at: 5.minutes.ago)
      _newer = create(:song_queue, user: user, song: later_song, source: SongQueue::SOURCE_USER_CUSTOM, created_at: 1.minute.ago)

      post next_players_path

      expect(user.play_histories.recent.first.song).to eq(queued_song)
      expect(user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM).pluck(:song_id)).to eq([ later_song.id ])
    end

    it 'falls back to artist shuffle when no pending user_custom entries exist' do
      sibling = create(:song, album: album, position: 5)
      create(:play_history, user: user, song: song, source: SongQueue::SOURCE_USER_CUSTOM, played_at: 1.minute.ago)

      post next_players_path

      shuffle_entry = user.song_queues.where(source: SongQueue::SOURCE_ARTIST_SHUFFLE).first
      expect(shuffle_entry).to be_present
      expect(shuffle_entry.song).to eq(sibling)
    end

    it 'does not create a song_queue row when popping from the custom queue' do
      create(:play_history, user: user, song: song, source: SongQueue::SOURCE_USER_CUSTOM, played_at: 1.minute.ago)
      create(:song_queue, user: user, song: queued_song, source: SongQueue::SOURCE_USER_CUSTOM)

      post next_players_path

      expect(user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM).count).to eq(0)
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
