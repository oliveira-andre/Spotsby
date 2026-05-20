require "rails_helper"

RSpec.describe "Heartable playlists", type: :system do
  let(:follower) { create(:user) }
  let(:owner)    { create(:user) }
  let(:author)   { create(:author, name: "Aut") }
  let(:album)    { create(:album,  name: "Alb", author: author) }
  let!(:song)    { create(:song,   name: "Track A", album: album) }
  let!(:playlist) do
    create(:playlist, user: owner, status: :public, name: "Owner's Public Mix").tap do |p|
      p.songs << song
    end
  end

  before { sign_in_as(follower) }

  describe "following a playlist" do
    it "saves the playlist to the follower's library without copying it" do
      visit playlist_path(playlist)

      click_button "Save playlist"

      expect(page).to have_button("Remove playlist from saved", wait: 5)
      expect(follower.followed_playlists).to include(playlist)
      expect(follower.playlists.where(name: playlist.name)).to be_empty

      visit library_path
      expect(page).to have_content("Followed playlists")
      expect(page).to have_content(playlist.name)
      expect(page).to have_content("By #{owner.email_address}")
    end

    it "reflects owner edits on the follower's library" do
      create(:playlist_follow, user: follower, playlist: playlist)
      playlist.update!(name: "Renamed By Owner")

      visit library_path
      expect(page).to have_content("Renamed By Owner")
    end

    it "removes the playlist from the library when unfollowed" do
      create(:playlist_follow, user: follower, playlist: playlist)

      visit playlist_path(playlist)
      click_button "Remove playlist from saved"

      expect(page).to have_button("Save playlist", wait: 5)
      visit library_path
      expect(page).not_to have_content(playlist.name)
    end
  end

  describe "song hearts inside a non-owned playlist" do
    it "lets a non-owner save individual songs to Saved Songs" do
      create(:playlist_follow, user: follower, playlist: playlist)

      visit playlist_path(playlist)

      within(:css, "li", text: song.name) { click_button "Save song" }
      within(:css, "li", text: song.name) do
        expect(page).to have_button("Remove from saved", wait: 5)
      end

      expect(follower.saved_songs_playlist.songs).to include(song)
    end
  end
end
