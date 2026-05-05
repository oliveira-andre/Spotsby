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
