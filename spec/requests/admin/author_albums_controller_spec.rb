require "rails_helper"

RSpec.describe Admin::AuthorAlbumsController, type: :request do
  let(:admin) { create(:user, status: :admin) }
  let(:author) { create(:author) }
  let(:category) { create(:category) }

  describe "POST /admin/authors/:author_id/albums" do
    before { sign_in(admin) }

    it "creates the album under the author and advances to the song step" do
      expect {
        post admin_author_albums_path(author),
             params: { album: { name: "Brand New", release_date: Date.today, category_id: category.id } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change { author.albums.count }.by(1)

      expect(response.body).to include("Save song")
    end

    it "re-renders the album step on validation failure" do
      post admin_author_albums_path(author),
           params: { album: { name: "", release_date: nil, category_id: nil } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("wizard-step")
    end
  end
end
