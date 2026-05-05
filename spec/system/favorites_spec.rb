require "rails_helper"

RSpec.describe "Favorites", type: :system do
  let(:user)   { create(:user) }
  let(:author) { create(:author, name: "Test Artist") }
  let(:album)  { create(:album,  name: "Test Album",  author: author) }
  let!(:song)  { create(:song,   name: "Test Song",   album: album) }

  before { sign_in_as(user) }

  describe "saving a song from the album page" do
    it "adds the song to the saved-songs playlist" do
      visit album_path(album)

      expect(user.saved_songs_playlist.songs.count).to eq(0)

      within(:css, "li", text: song.name) { click_button "Save song" }

      within(:css, "li", text: song.name) do
        expect(page).to have_button("Remove from saved", wait: 5)
      end
      expect(user.saved_songs_playlist.songs).to include(song)
    end
  end

  describe "saving an entire album" do
    before { create(:song, name: "Second Track", album: album) }

    it "creates a mirror playlist that contains every album song" do
      visit album_path(album)
      click_button "Save album"

      expect(page).to have_button("Remove album from saved", wait: 5)

      mirror = user.playlists.find_by(name: album.name)
      expect(mirror).to be_present
      expect(mirror.songs.count).to eq(2)
    end
  end

  describe "saved songs visible from the library" do
    it "lists the saved-songs playlist with the right count" do
      visit album_path(album)
      within(:css, "li", text: song.name) { click_button "Save song" }
      within(:css, "li", text: song.name) do
        expect(page).to have_button("Remove from saved", wait: 5)
      end

      visit library_path
      saved = user.saved_songs_playlist
      saved_link = find_link(href: playlist_path(saved))
      expect(saved_link).to have_text("Saved Songs")
      expect(saved_link).to have_text("1 song")
    end
  end
end
