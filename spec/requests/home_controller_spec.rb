require 'rails_helper'

RSpec.describe HomeController, type: :request do
  let(:user) { create(:user) }

  context 'when not authenticated' do
    it 'redirects the root to the sign-in page' do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context 'when authenticated' do
    before { sign_in(user) }

    describe 'GET /' do
      it 'renders the index with empty feed' do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the index with seeded queue data' do
        song = create(:song)
        create(:song_queue, user: user, song: song, source: SongQueue::SOURCE_DEFAULT)

        get root_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /home_all' do
      it 'renders' do
        get home_all_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /search' do
      it 'renders the search page' do
        get search_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /search/results' do
      it 'returns no records for a blank query' do
        get search_results_path,
            params: { q: '' },
            headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      end

      it 'returns matching records for a query' do
        author = create(:author, name: 'Searchable Artist')
        album = create(:album, name: 'Searchable Album', author: author)
        create(:song, name: 'Searchable Song', album: album)

        get search_results_path,
            params: { q: 'Searchable' },
            headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Searchable')
      end
    end

    describe 'GET /library' do
      it 'renders the library' do
        get library_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /manage' do
      it 'renders' do
        get manage_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /recent_albums' do
      it 'renders' do
        get recent_albums_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /recent_artists' do
      it 'renders' do
        get recent_artists_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'when blocked' do
    let(:blocked_user) { create(:user, status: :blocked) }

    it 'redirects to login with an alert' do
      sign_in(blocked_user)
      get root_path
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to be_present
    end
  end
end
