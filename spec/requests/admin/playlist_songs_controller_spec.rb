require "rails_helper"

RSpec.describe Admin::PlaylistSongsController, type: :request do
  let(:admin) { create(:user, status: :admin) }
  let(:playlist) { create(:playlist, name: "Mix") }
  let(:author) { create(:author, name: "Author One") }
  let(:album) { create(:album, author: author, name: "Album One") }
  let!(:song_one) { create(:song, album: album, name: "Track One") }
  let!(:song_two) { create(:song, album: album, name: "Other Track") }

  describe "GET /admin/playlists/:playlist_id/songs/picker" do
    before { sign_in(admin) }

    it "lists recent songs without a query" do
      get picker_admin_playlist_songs_path(playlist),
          headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Track One")
      expect(response.body).to include("Other Track")
    end

    it "filters by song name" do
      get picker_admin_playlist_songs_path(playlist),
          params: { q: "Other" },
          headers: { "Accept" => "text/html" }

      expect(response.body).to include("Other Track")
      expect(response.body).not_to include(">Track One<")
    end

    it "filters by author name" do
      get picker_admin_playlist_songs_path(playlist),
          params: { q: "Author One" },
          headers: { "Accept" => "text/html" }

      expect(response.body).to include("Track One")
    end

    it "marks already-added songs" do
      playlist.songs << song_one

      get picker_admin_playlist_songs_path(playlist),
          headers: { "Accept" => "text/html" }

      expect(response.body).to include("Added")
    end
  end

  describe "POST /admin/playlists/:playlist_id/songs" do
    before { sign_in(admin) }

    it "adds the song to the playlist" do
      expect {
        post admin_playlist_songs_path(playlist),
             params: { song_id: song_one.id },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change { playlist.songs.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Added")
    end

    it "is idempotent for songs already in the playlist" do
      playlist.songs << song_one

      expect {
        post admin_playlist_songs_path(playlist),
             params: { song_id: song_one.id },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change { playlist.songs.count }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /admin/playlists/:playlist_id/songs/:id" do
    before do
      sign_in(admin)
      playlist.songs << song_one
    end

    it "removes the song from the playlist" do
      expect {
        delete admin_playlist_song_path(playlist, song_one),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change { playlist.songs.count }.by(-1)

      expect(response.body).to include("Add")
    end
  end

  describe "authorization" do
    it "rejects regular users" do
      sign_in(create(:user))
      get picker_admin_playlist_songs_path(playlist),
          headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
