require "rails_helper"

RSpec.describe "Player", type: :system do
  let(:user)   { create(:user) }
  let(:author) { create(:author, name: "Player Artist") }
  let(:album)  { create(:album,  name: "Player Album", author: author) }
  let!(:song1) { create(:song,   name: "Track One",    album: album, position: 1) }
  let!(:song2) { create(:song,   name: "Track Two",    album: album, position: 2) }

  before { sign_in_as(user) }

  it "opens a song from the album page and renders the player UI" do
    visit album_path(album)

    within(:css, "li", text: song1.name) { click_link song1.name }

    expect(page).to have_link(song1.name, wait: 5)
    expect(page).to have_button("Previous")
    expect(page).to have_button("Next")
    expect(page).to have_button("Play")
  end

  it "advances to the next album track via Next" do
    visit player_path(song1, source: SongQueue::SOURCE_ALBUM)
    expect(page).to have_link(song1.name, wait: 5)

    click_button "Next"

    expect(page).to have_link(song2.name, wait: 5)
    expect(user.song_queues.where(song: song2)).to exist
  end

  it "goes back to the previous album track via Previous" do
    visit player_path(song2, source: SongQueue::SOURCE_ALBUM)
    expect(page).to have_link(song2.name, wait: 5)

    click_button "Previous"

    expect(page).to have_link(song1.name, wait: 5)
    expect(user.song_queues.where(song: song1)).to exist
  end

  it "records a play history entry when the player opens" do
    expect {
      visit player_path(song1, source: SongQueue::SOURCE_ALBUM)
      expect(page).to have_link(song1.name, wait: 5)
    }.to change { user.play_histories.count }.by(1)
  end
end
