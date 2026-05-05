require 'rails_helper'

RSpec.describe AlbumsController, type: :request do
  let(:user) { create(:user) }
  let(:album) { create(:album) }

  context 'when not authenticated' do
    it 'redirects to login' do
      get album_path(album)
      expect(response).to redirect_to(new_session_path)
    end
  end

  context 'when authenticated' do
    before { sign_in(user) }

    describe 'GET /albums/:id' do
      it 'renders the album' do
        create(:song, album: album)
        get album_path(album)
        expect(response).to have_http_status(:ok)
      end

      it 'finds by slug' do
        create(:song, album: album)
        get album_path(album.slug)
        expect(response).to have_http_status(:ok)
      end

      it '404s for unknown album' do
        get album_path('does-not-exist')
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
