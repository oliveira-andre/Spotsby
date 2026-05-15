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

    describe 'POST /playlists/:id/random_song' do
      it 'redirects to the player for one of the playlist songs' do
        playlist = create(:playlist, user: user)
        song_a = create(:song)
        song_b = create(:song)
        create(:playlist_song, playlist: playlist, song: song_a)
        create(:playlist_song, playlist: playlist, song: song_b)

        post random_song_playlist_path(playlist)
        expect(response).to be_redirect
        expect(response.location).to match(
          %r{/players/(#{song_a.slug}|#{song_b.slug})\?playlist_id=#{playlist.id}&source=#{SongQueue::SOURCE_PLAYLIST}}
        )
      end

      it 'redirects back to the playlist when there are no songs' do
        playlist = create(:playlist, user: user)
        post random_song_playlist_path(playlist)
        expect(response).to redirect_to(playlist_path(playlist))
      end
    end

    describe 'PATCH /playlists/:id/update_position' do
      let!(:playlist_a) { create(:playlist, user: user) }
      let!(:playlist_b) { create(:playlist, user: user) }
      let!(:playlist_c) { create(:playlist, user: user) }

      it 'reorders the playlist within the user scope' do
        patch update_position_playlist_path(playlist_a.id), params: { position: 3 }

        expect(response).to have_http_status(:ok)
        ordered_ids = user.playlists.where.not(position: 0).ordered.pluck(:id)
        expect(ordered_ids).to eq([ playlist_b.id, playlist_c.id, playlist_a.id ])
      end

      it 'forbids moving the pinned saved-songs playlist (position 0)' do
        saved = user.saved_songs_playlist
        expect {
          patch update_position_playlist_path(saved.id), params: { position: 2 }
        }.not_to change { saved.reload.position }

        expect(response).to have_http_status(:forbidden)
      end

      it 'rejects positions below 1' do
        patch update_position_playlist_path(playlist_a.id), params: { position: 0 }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns not found when the playlist belongs to another user' do
        intruder = create(:user)
        sign_in(intruder)

        patch update_position_playlist_path(playlist_a.id), params: { position: 2 }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /playlists/:id/update_name' do
      it 'renders the edit form inside the playlist_name turbo-frame' do
        playlist = create(:playlist, user: user)
        get update_name_playlist_path(playlist)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('turbo-frame id="playlist_name"')
        expect(response.body).to include("playlist[name]")
      end

      it 'allows renaming the pinned saved-songs playlist' do
        get update_name_playlist_path(user.saved_songs_playlist)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH /playlists/:id/update_name' do
      it 'updates the name and renders the display partial' do
        playlist = create(:playlist, user: user, name: "Old")

        patch update_name_playlist_path(playlist), params: { playlist: { name: "New" } }

        expect(playlist.reload.name).to eq("New")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('turbo-frame id="playlist_name"')
        expect(response.body).to include("New")
      end

      it 'renames the pinned saved-songs playlist' do
        saved = user.saved_songs_playlist

        patch update_name_playlist_path(saved), params: { playlist: { name: "Heart" } }

        expect(saved.reload.name).to eq("Heart")
        expect(response).to have_http_status(:ok)
      end

      it 're-renders the form with errors on a blank name' do
        playlist = create(:playlist, user: user, name: "Keep")

        patch update_name_playlist_path(playlist), params: { playlist: { name: "" } }

        expect(playlist.reload.name).to eq("Keep")
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("playlist[name]")
      end

      it 'returns not found when the playlist belongs to another user' do
        playlist = create(:playlist, user: user)
        sign_in(create(:user))

        patch update_name_playlist_path(playlist), params: { playlist: { name: "Hack" } }
        expect(response).to have_http_status(:not_found)
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
