require "rails_helper"

RSpec.describe Admin::AlbumSongsController, type: :request do
  let(:admin) { create(:user, status: :admin) }
  let(:category) { create(:category) }
  let(:author) { create(:author) }
  let(:album) { create(:album, author: author, category: category) }

  describe "POST /admin/authors/:author_id/albums/:album_id/songs" do
    before { sign_in(admin) }

    it "creates the song, links it to the author, and renders next-song form" do
      expect {
        post admin_author_album_songs_path(author, album),
             params: { song: { name: "First Song", duration_ms: 180_000, age: 0 } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change { album.songs.count }.by(1)

      created = album.songs.last
      expect(created.authors).to include(author)
      expect(created.category).to eq(album.category)
      expect(response.body).to include("Save song")
      expect(response.body).to include("First Song")
    end

    it "lets the user pass an explicit category that overrides the album's" do
      other = create(:category)

      post admin_author_album_songs_path(author, album),
           params: { song: { name: "Custom Cat", duration_ms: 0, age: 0, category_id: other.id } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(album.songs.last.category).to eq(other)
    end

    it "re-renders the song step on validation failure" do
      post admin_author_album_songs_path(author, album),
           params: { song: { name: "" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("wizard-step")
    end
  end
end
