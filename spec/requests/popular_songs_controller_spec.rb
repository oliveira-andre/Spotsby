require "rails_helper"

RSpec.describe PopularSongsController, type: :request do
  let(:viewer) { create(:user) }
  let(:admin) { create(:user, status: :admin) }
  let(:owner) { create(:user) }
  let(:author) { create(:author, user: owner) }
  let(:album) { create(:album, author: author) }
  let(:song_a) { create(:song, album: album) }
  let(:song_b) { create(:song, album: album) }
  let!(:popular_a) { PopularSong.create!(author: author, song: song_a, position: 1) }
  let!(:popular_b) { PopularSong.create!(author: author, song: song_b, position: 2) }

  describe "PATCH /authors/:author_id/popular_songs/:id/update_position" do
    context "as the author's owning user" do
      before { sign_in(owner) }

      it "reorders the popular song" do
        patch update_position_author_popular_song_path(author, popular_b),
              params: { position: 1 }
        expect(response).to have_http_status(:ok)
        expect(popular_b.reload.position).to eq(1)
        expect(popular_a.reload.position).to eq(2)
      end
    end

    context "as an admin" do
      before { sign_in(admin) }

      it "reorders the popular song" do
        patch update_position_author_popular_song_path(author, popular_b),
              params: { position: 1 }
        expect(response).to have_http_status(:ok)
        expect(popular_b.reload.position).to eq(1)
      end
    end

    context "as an unrelated user" do
      before { sign_in(viewer) }

      it "is forbidden" do
        patch update_position_author_popular_song_path(author, popular_b),
              params: { position: 1 }
        expect(response).to have_http_status(:forbidden)
        expect(popular_b.reload.position).to eq(2)
      end
    end

    context "when the author has no owning user" do
      let(:author) { create(:author, user: nil) }

      before { sign_in(viewer) }

      it "is forbidden for a non-admin" do
        patch update_position_author_popular_song_path(author, popular_b),
              params: { position: 1 }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "validation" do
      before { sign_in(owner) }

      it "rejects a position below 1" do
        patch update_position_author_popular_song_path(author, popular_b),
              params: { position: 0 }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns 404 when the popular song does not belong to the author" do
        other_author = create(:author, user: owner)
        stray = PopularSong.create!(author: other_author, song: song_a, position: 1)

        patch update_position_author_popular_song_path(author, stray),
              params: { position: 1 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
