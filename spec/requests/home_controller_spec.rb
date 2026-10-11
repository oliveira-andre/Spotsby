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

      context 'with songs leading and albums and artists in their own sections' do
        let(:author) { create(:author, name: 'Night Owls') }
        let(:album) { create(:album, name: 'Midnight Drive', author: author) }
        let!(:song) { create(:song, name: 'Neon Lights', album: album) }

        before { create(:song_author, song: song, author: author) }

        def search(query)
          get search_results_path, params: { q: query }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        end

        def section(title)
          Nokogiri::HTML(response.body).css('.search-results__group')
                  .find { |group| group.at_css('.search-results__title')&.text == title }
        end

        it "lists a song found by its author's name" do
          search('Night Owls')
          expect(response.body).to include("players/#{song.slug}")
        end

        it 'lists a song found by its album name, despite a typo' do
          search('midnite drive')
          expect(response.body).to include("players/#{song.slug}")
        end

        it "shows the album and artist of a song found by the song's own name" do
          search('neon lights')

          expect(section('Albums').to_html).to include(album_path(album))
          expect(section('Artists').to_html).to include(author_path(author))
        end

        it 'still shows an album and an artist that match by name but have no matching song' do
          lonely_author = create(:author, name: 'Solo Comet')
          lonely_album = create(:album, name: 'Solo Comet Live', author: create(:author))

          search('solo comet')

          expect(section('Artists').to_html).to include(author_path(lonely_author))
          expect(section('Albums').to_html).to include(album_path(lonely_album))
          expect(section('Songs')).to be_nil
        end

        it 'does not find a song by the name of a playlist it is in' do
          create(:playlist_song, song: song, playlist: create(:playlist, name: 'Road Trip', status: :public))
          search('road trip')
          expect(response.body).not_to include("players/#{song.slug}")
        end

        it 'finds a public playlist by its name despite a typo' do
          playlist = create(:playlist, user: create(:user), name: 'Road Trip', status: :public)
          search('road trp')
          expect(section('Playlists').to_html).to include(playlist_path(playlist))
        end
      end

      it 'includes a public playlist whose name matches the query' do
        other_user = create(:user)
        public_playlist = create(:playlist, user: other_user, status: :public, name: 'Searchable Playlist')

        get search_results_path,
            params: { q: 'Searchable' },
            headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Searchable Playlist')
        expect(response.body).to include(playlist_path(public_playlist))
      end

      it 'omits a private playlist even when the name matches' do
        other_user = create(:user)
        create(:playlist, user: other_user, status: :private, name: 'Hidden Mix')

        get search_results_path,
            params: { q: 'Hidden' },
            headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('Hidden Mix')
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

  # A blocked account can't sign in at all (see the sessions spec). This
  # covers a user who is blocked while already holding a session.
  context 'when blocked during a session' do
    let(:user) { create(:user) }

    it 'redirects to login with an alert' do
      sign_in(user)
      user.update!(status: :blocked)
      get root_path
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to be_present
    end
  end
end
