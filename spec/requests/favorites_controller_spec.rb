require 'rails_helper'

RSpec.describe FavoritesController, type: :request do
  let(:user) { create(:user) }
  let(:album) { create(:album) }
  let(:song) { create(:song, album: album) }
  let(:turbo_headers) { { 'Accept' => 'text/vnd.turbo-stream.html' } }

  before { sign_in(user) }

  describe 'POST /favorites/songs/:id (create_song)' do
    it 'adds the song to the user saved-songs playlist' do
      expect {
        post song_favorites_path(song), headers: turbo_headers
      }.to change { user.saved_songs_playlist.songs.count }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it 'is idempotent for an already-saved song' do
      post song_favorites_path(song), headers: turbo_headers

      expect {
        post song_favorites_path(song), headers: turbo_headers
      }.not_to change { PlaylistSong.where(playlist: user.saved_songs_playlist).count }
    end
  end

  describe 'DELETE /favorites/songs/:id (destroy_song)' do
    it 'removes the song from every user playlist' do
      post song_favorites_path(song), headers: turbo_headers

      expect {
        delete song_favorites_path(song), headers: turbo_headers
      }.to change { PlaylistSong.where(playlist_id: user.playlist_ids, song_id: song.id).count }.to(0)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /favorites/songs/:id/modal' do
    it 'renders the playlists modal' do
      create(:playlist, user: user, name: 'My Mix')

      post song_modal_favorites_path(song), headers: turbo_headers
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    end
  end

  describe 'POST /favorites/songs/:id/playlists/:playlist_id (add_to_playlist)' do
    let!(:playlist) { create(:playlist, user: user, name: 'Roadtrip') }

    it 'adds the song to the chosen playlist' do
      expect {
        post add_song_to_playlist_favorites_path(song, playlist_id: playlist.id), headers: turbo_headers
      }.to change { playlist.reload.songs.count }.by(1)
    end

    it 'removes the song from saved-songs when present' do
      post song_favorites_path(song), headers: turbo_headers

      expect {
        post add_song_to_playlist_favorites_path(song, playlist_id: playlist.id), headers: turbo_headers
      }.to change { user.saved_songs_playlist.reload.songs.count }.by(-1)
    end
  end

  describe 'DELETE /favorites/songs/:id/playlists/:playlist_id (remove_from_playlist)' do
    let!(:playlist) { create(:playlist, user: user, name: 'Roadtrip') }

    before { playlist.songs << song }

    it 'removes the song from the playlist' do
      expect {
        delete remove_song_from_playlist_favorites_path(song, playlist_id: playlist.id), headers: turbo_headers
      }.to change { playlist.reload.songs.count }.by(-1)
    end
  end

  describe 'POST /favorites/albums/:id (create_album)' do
    it 'creates a playlist that mirrors the album' do
      create(:song, album: album)
      create(:song, album: album)

      expect {
        post album_favorites_path(album), headers: turbo_headers
      }.to change { user.playlists.where(name: album.name).count }.by(1)

      mirror = user.playlists.find_by(name: album.name)
      expect(mirror.songs.count).to eq(2)
    end

    it 'is idempotent' do
      create(:song, album: album)
      post album_favorites_path(album), headers: turbo_headers

      expect {
        post album_favorites_path(album), headers: turbo_headers
      }.not_to change { user.playlists.where(name: album.name).count }
    end
  end

  describe 'DELETE /favorites/albums/:id (destroy_album)' do
    it 'destroys the mirror playlist when present' do
      create(:song, album: album)
      post album_favorites_path(album), headers: turbo_headers

      expect {
        delete album_favorites_path(album), headers: turbo_headers
      }.to change { user.playlists.where(name: album.name).count }.by(-1)
    end

    it 'is a no-op when no mirror playlist exists' do
      expect {
        delete album_favorites_path(album), headers: turbo_headers
      }.not_to change { user.playlists.count }

      expect(response).to have_http_status(:ok)
    end
  end
end
