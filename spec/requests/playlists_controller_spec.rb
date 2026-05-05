require 'rails_helper'

RSpec.describe PlaylistsController, type: :request do
  let(:user) { create(:user) }

  context 'when not authenticated' do
    it 'redirects to login' do
      playlist = user.playlists.first
      get playlist_path(playlist)
      expect(response).to redirect_to(new_session_path)
    end
  end

  context 'when authenticated' do
    before { sign_in(user) }

    describe 'GET /playlists/:id' do
      it 'renders the playlist with its songs' do
        playlist = create(:playlist, user: user)
        playlist.songs << create(:song)

        get playlist_path(playlist)
        expect(response).to have_http_status(:ok)
      end

      it 'finds by slug' do
        playlist = create(:playlist, user: user)
        get playlist_path(playlist.slug)
        expect(response).to have_http_status(:ok)
      end

      it 'renders the auto-created saved-songs playlist' do
        get playlist_path(user.saved_songs_playlist)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

RSpec.describe PlaylistSongsController, type: :request do
  let(:user) { create(:user) }
  let(:playlist) { create(:playlist, user: user) }
  let(:song_a) { create(:song) }
  let(:song_b) { create(:song) }
  let(:song_c) { create(:song) }

  before do
    create(:playlist_song, playlist: playlist, song: song_a)
    create(:playlist_song, playlist: playlist, song: song_b)
    create(:playlist_song, playlist: playlist, song: song_c)
  end

  describe 'PATCH /playlists/:playlist_id/songs/:id/update_position' do
    context 'when not authenticated' do
      it 'redirects to login' do
        patch update_position_playlist_song_path(playlist, song_a.id), params: { position: 3 }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when authenticated as the owner' do
      before { sign_in(user) }

      it 'updates the position of the playlist song' do
        patch update_position_playlist_song_path(playlist, song_a.id), params: { position: 3 }

        expect(response).to have_http_status(:ok)
        ordered_song_ids = playlist.playlist_songs.ordered.pluck(:song_id)
        expect(ordered_song_ids).to eq([ song_b.id, song_c.id, song_a.id ])
      end

      it 'returns not found when the song is not in the playlist' do
        other_song = create(:song)
        patch update_position_playlist_song_path(playlist, other_song.id), params: { position: 1 }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when authenticated as a non-owner' do
      let(:intruder) { create(:user) }

      before { sign_in(intruder) }

      it 'does not allow updating positions on a playlist they do not own' do
        expect {
          patch update_position_playlist_song_path(playlist, song_a.id), params: { position: 3 }
        }.not_to change { playlist.playlist_songs.ordered.pluck(:song_id) }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
