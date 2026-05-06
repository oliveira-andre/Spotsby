require 'rails_helper'

RSpec.describe AuthorsController, type: :request do
  let(:user) { create(:user) }
  let(:author) { create(:author) }

  context 'when not authenticated' do
    it 'redirects to login' do
      get author_path(author)
      expect(response).to redirect_to(new_session_path)
    end
  end

  context 'when authenticated' do
    before { sign_in(user) }

    describe 'GET /authors/:id' do
      it 'renders the author' do
        album = create(:album, author: author)
        song = create(:song, album: album)
        PopularSong.create!(author: author, song: song, position: 1)

        get author_path(author)
        expect(response).to have_http_status(:ok)
      end

      it 'finds by slug' do
        get author_path(author.slug)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /authors/:id/all_songs' do
      it 'renders the song list' do
        album = create(:album, author: author)
        create(:song, album: album)

        get all_songs_author_path(author)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST /authors/:id/random_song' do
      it 'redirects to the player for one of the popular songs' do
        album = create(:album, author: author)
        song_a = create(:song, album: album)
        song_b = create(:song, album: album)
        PopularSong.create!(author: author, song: song_a, position: 1)
        PopularSong.create!(author: author, song: song_b, position: 2)

        post random_song_author_path(author)
        expect(response).to be_redirect
        expect(response.location).to match(%r{/players/(#{song_a.slug}|#{song_b.slug})\?source=#{SongQueue::SOURCE_POPULAR}})
      end

      it 'redirects back to the author when there are no popular songs' do
        post random_song_author_path(author)
        expect(response).to redirect_to(author_path(author))
      end
    end
  end
end
