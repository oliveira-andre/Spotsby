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

RSpec.describe AlbumSongsController, type: :request do
  let(:user) { create(:user) }
  let(:author) { create(:author, user: user) }
  let(:album) { create(:album, author: author) }
  let!(:song_a) { create(:song, album: album) }
  let!(:song_b) { create(:song, album: album) }
  let!(:song_c) { create(:song, album: album) }

  describe 'PATCH /albums/:album_id/songs/:id/update_position' do
    context 'when not authenticated' do
      it 'redirects to login' do
        patch update_position_album_song_path(album, song_a.id), params: { position: 3 }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when authenticated as the author owner' do
      before { sign_in(user) }

      it 'reorders the song' do
        patch update_position_album_song_path(album, song_a.id), params: { position: 3 }

        expect(response).to have_http_status(:ok)
        expect(album.songs.ordered.pluck(:id)).to eq([ song_b.id, song_c.id, song_a.id ])
      end

      it 'returns not found when the song is not in the album' do
        other_song = create(:song)
        patch update_position_album_song_path(album, other_song.id), params: { position: 1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'rejects positions below 1' do
        patch update_position_album_song_path(album, song_a.id), params: { position: 0 }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when the author has no user' do
      let(:author) { create(:author, user: nil) }

      before { sign_in(user) }

      it 'forbids sorting' do
        patch update_position_album_song_path(album, song_a.id), params: { position: 3 }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as a non-owner' do
      let(:intruder) { create(:user) }

      before { sign_in(intruder) }

      it 'forbids sorting' do
        patch update_position_album_song_path(album, song_a.id), params: { position: 3 }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
