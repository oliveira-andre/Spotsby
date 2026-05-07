require "rails_helper"

RSpec.describe Admin::SongsController, type: :request do
  let(:admin) { create(:user, status: :admin) }
  let(:category) { create(:category) }
  let(:author_a) { create(:author, name: "Aaron Author") }
  let(:author_b) { create(:author, name: "Zara Zebra") }
  let(:album_a) { create(:album, author: author_a, category: category, name: "Aaron Album") }
  let(:album_b) { create(:album, author: author_b, category: category, name: "Zara Album") }
  let!(:song_a) { create(:song, album: album_a, category: category, name: "Alpha Track") }
  let!(:song_b) { create(:song, album: album_b, category: category, name: "Bravo Track") }

  describe "GET /admin/songs" do
    context "without admin" do
      it "rejects non-admin users" do
        sign_in(create(:user))
        get admin_songs_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "lists every song by default" do
        get admin_songs_path
        expect(response.body).to include("Alpha Track")
        expect(response.body).to include("Bravo Track")
      end

      it "filters by song name" do
        get admin_songs_path, params: { q: "Alpha" }
        expect(response.body).to include("Alpha Track")
        expect(response.body).not_to include("Bravo Track")
      end

      it "filters by album name" do
        get admin_songs_path, params: { q: "Zara Album" }
        expect(response.body).to include("Bravo Track")
        expect(response.body).not_to include("Alpha Track")
      end

      it "filters by author name" do
        get admin_songs_path, params: { q: "Aaron" }
        expect(response.body).to include("Alpha Track")
        expect(response.body).not_to include("Bravo Track")
      end

      it "filters by author_id" do
        get admin_songs_path, params: { author_id: author_a.id }
        expect(response.body).to include("Alpha Track")
        expect(response.body).not_to include("Bravo Track")
      end

      it "filters by album_id" do
        get admin_songs_path, params: { album_id: album_b.id }
        expect(response.body).to include("Bravo Track")
        expect(response.body).not_to include("Alpha Track")
      end

      it "sorts by author ascending" do
        get admin_songs_path, params: { sort: "author", dir: "asc" }
        body = response.body
        expect(body.index("Alpha Track")).to be < body.index("Bravo Track")
      end

      it "sorts by author descending" do
        get admin_songs_path, params: { sort: "author", dir: "desc" }
        body = response.body
        expect(body.index("Bravo Track")).to be < body.index("Alpha Track")
      end

      it "sorts by album ascending" do
        get admin_songs_path, params: { sort: "album", dir: "asc" }
        body = response.body
        expect(body.index("Alpha Track")).to be < body.index("Bravo Track")
      end

      it "ignores unknown sort and dir" do
        get admin_songs_path, params: { sort: "haxxor", dir: "drop tables" }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /admin/songs/new" do
    before { sign_in(admin) }

    it "renders the wizard with author picker" do
      get new_admin_song_path
      expect(response.body).to include("New song")
      expect(response.body).to include(author_a.name)
    end
  end

  describe "POST /admin/songs/select_author" do
    before { sign_in(admin) }

    it "advances to the album picker for that author" do
      post select_author_admin_songs_path,
           params: { author_id: author_a.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aaron Album")
      expect(response.body).not_to include("Zara Album")
    end
  end

  describe "POST /admin/songs/select_album" do
    before { sign_in(admin) }

    it "advances to the song form" do
      post select_album_admin_songs_path,
           params: { author_id: author_a.id, album_id: album_a.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save song")
    end
  end

  describe "PATCH /admin/songs/:id" do
    before { sign_in(admin) }

    it "updates and re-renders the row" do
      patch admin_song_path(song_a),
            params: { song: { name: "Renamed Track" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(song_a.reload.name).to eq("Renamed Track")
      expect(response.body).to include("Renamed Track")
    end
  end

  describe "DELETE /admin/songs/:id" do
    before { sign_in(admin) }

    it "destroys the song" do
      expect {
        delete admin_song_path(song_a),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Song, :count).by(-1)
    end
  end
end
