require "rails_helper"

RSpec.describe Admin::AlbumsController, type: :request do
  let(:admin) { create(:user, status: :admin) }
  let(:author) { create(:author) }
  let(:category) { create(:category) }
  let!(:album) { create(:album, author: author, category: category, name: "First Album") }

  describe "GET /admin/albums" do
    context "without admin" do
      it "redirects when not signed in" do
        get admin_albums_path
        expect(response).to redirect_to(new_session_path)
      end

      it "rejects non-admin users" do
        sign_in(create(:user))
        get admin_albums_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "renders the index" do
        get admin_albums_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("First Album")
      end

      it "filters by name" do
        create(:album, author: author, name: "Other")

        get admin_albums_path, params: { q: "First" }

        expect(response.body).to include("First Album")
        expect(response.body).not_to include(">Other<")
      end

      it "filters by author name via the joined author" do
        other_author = create(:author, name: "Famous Person")
        create(:album, author: other_author, name: "Solo Hits")

        get admin_albums_path, params: { q: "Famous" }

        expect(response.body).to include("Solo Hits")
        expect(response.body).not_to include("First Album")
      end
    end
  end

  describe "GET /admin/albums/new" do
    before { sign_in(admin) }

    it "renders the wizard with author picker" do
      get new_admin_album_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New album")
      expect(response.body).to include(author.name)
    end
  end

  describe "POST /admin/albums/select_author" do
    before { sign_in(admin) }

    it "advances the wizard to the album form" do
      post select_author_admin_albums_path,
           params: { author_id: author.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("wizard-step")
      expect(response.body).to include("Save and continue")
    end

    it "404s for an unknown author" do
      post select_author_admin_albums_path,
           params: { author_id: 0 },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/albums/:id/edit" do
    before { sign_in(admin) }

    it "renders the edit form" do
      get edit_admin_album_path(album)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit album")
    end
  end

  describe "PATCH /admin/albums/:id" do
    before { sign_in(admin) }

    it "updates the album and renders a turbo stream" do
      patch admin_album_path(album),
            params: { album: { name: "Renamed" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(album.reload.name).to eq("Renamed")
      expect(response.body).to include("Renamed")
    end

    it "re-renders the form with errors" do
      patch admin_album_path(album),
            params: { album: { name: "" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("can&#39;t be blank")
    end
  end

  describe "DELETE /admin/albums/:id" do
    before { sign_in(admin) }

    it "removes the album" do
      expect {
        delete admin_album_path(album),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Album, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end
end
