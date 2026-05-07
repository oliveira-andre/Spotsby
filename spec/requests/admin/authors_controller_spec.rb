require "rails_helper"

RSpec.describe Admin::AuthorsController, type: :request do
  let(:admin) { create(:user, status: :admin) }
  let!(:author) { create(:author, name: "Some Singer") }

  describe "GET /admin/authors" do
    it "redirects when signed out" do
      get admin_authors_path
      expect(response).to redirect_to(new_session_path)
    end

    it "rejects regular users" do
      sign_in(create(:user))
      get admin_authors_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "as admin" do
      before { sign_in(admin) }

      it "renders the index with album count badges" do
        category = create(:category)
        create(:album, author: author, category: category, name: "Album 1")
        create(:album, author: author, category: category, name: "Album 2")

        get admin_authors_path

        expect(response.body).to include("Some Singer")
        expect(response.body).to include("2 albums")
      end

      it "filters by name or description" do
        create(:author, name: "Other", description: "Different artist")

        get admin_authors_path, params: { q: "Singer" }

        expect(response.body).to include("Some Singer")
        expect(response.body).not_to include(">Other<")
      end
    end
  end

  describe "GET /admin/authors/new" do
    before { sign_in(admin) }

    it "renders the wizard step 1" do
      get new_admin_author_path
      expect(response.body).to include("New author")
    end
  end

  describe "POST /admin/authors" do
    before { sign_in(admin) }

    it "creates the author and advances the wizard to the album step" do
      expect {
        post admin_authors_path,
             params: { author: { name: "Brand New" } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Author, :count).by(1)

      expect(response.body).to include("wizard-step")
      expect(response.body).to include("Save and continue")
    end

    it "re-renders step 1 on validation failure" do
      post admin_authors_path,
           params: { author: { name: "" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("can&#39;t be blank")
    end
  end

  describe "PATCH /admin/authors/:id" do
    before { sign_in(admin) }

    it "updates the author" do
      patch admin_author_path(author),
            params: { author: { name: "Renamed" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(author.reload.name).to eq("Renamed")
    end
  end

  describe "DELETE /admin/authors/:id" do
    before { sign_in(admin) }

    it "destroys the author" do
      expect {
        delete admin_author_path(author),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Author, :count).by(-1)
    end
  end
end
