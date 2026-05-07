require "rails_helper"

RSpec.describe Admin::PlaylistsController, type: :request do
  let(:admin) { create(:user, status: :admin) }
  let(:owner) { create(:user) }
  let!(:playlist) { create(:playlist, user: owner, name: "Chill Mix") }

  describe "GET /admin/playlists" do
    context "without admin" do
      it "redirects when signed out" do
        get admin_playlists_path
        expect(response).to redirect_to(new_session_path)
      end

      it "rejects regular users" do
        sign_in(create(:user))
        get admin_playlists_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "lists playlists across all users" do
        get admin_playlists_path
        expect(response.body).to include("Chill Mix")
        expect(response.body).to include(owner.email_address)
      end

      it "filters by name" do
        create(:playlist, user: owner, name: "Workout Beats")
        get admin_playlists_path, params: { q: "Workout" }

        expect(response.body).to include("Workout Beats")
        expect(response.body).not_to include("Chill Mix")
      end
    end
  end

  describe "GET /admin/playlists/new" do
    before { sign_in(admin) }

    it "renders the wizard's first step" do
      get new_admin_playlist_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New playlist")
      expect(response.body).to include(owner.email_address)
    end
  end

  describe "POST /admin/playlists" do
    before { sign_in(admin) }

    it "creates the playlist and advances to the song-picker step" do
      expect {
        post admin_playlists_path,
             params: { playlist: { name: "Brand New", user_id: owner.id, status: "private" } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Playlist, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("playlist-picker")
      expect(response.body).to include("Brand New")
    end

    it "re-renders the form on validation failure" do
      post admin_playlists_path,
           params: { playlist: { name: "", user_id: owner.id, status: "private" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("can&#39;t be blank")
    end
  end

  describe "GET /admin/playlists/:id/edit" do
    before { sign_in(admin) }

    it "renders the edit form" do
      get edit_admin_playlist_path(playlist)
      expect(response.body).to include("Edit playlist")
    end
  end

  describe "PATCH /admin/playlists/:id" do
    before { sign_in(admin) }

    it "updates and re-renders the row" do
      patch admin_playlist_path(playlist),
            params: { playlist: { name: "Renamed" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(playlist.reload.name).to eq("Renamed")
      expect(response.body).to include("Renamed")
    end
  end

  describe "DELETE /admin/playlists/:id" do
    before { sign_in(admin) }

    it "destroys the playlist" do
      expect {
        delete admin_playlist_path(playlist),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Playlist, :count).by(-1)
    end
  end
end
