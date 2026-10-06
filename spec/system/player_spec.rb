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

  # Helpers for the examples that play real audio.

  def attach_sample_audio(*songs)
    fixture_path = Rails.root.join("spec/fixtures/files/sample.mp3")
    songs.each do |song|
      song.audio.attach(io: File.open(fixture_path, "rb"), filename: "sample.mp3", content_type: "audio/mpeg")
    end
  end

  def start_playing(song)
    visit player_path(song, source: SongQueue::SOURCE_ALBUM)
    expect(page).to have_link(song.name, wait: 5)
    click_button "Play"
    expect(page).to have_button("Pause", wait: 5)
  end

  # Position as the now-playing controller sees it, which is what decides
  # between rewinding and going back.
  def controller_time
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.getElementById("minimal-player")
        const ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, "now-playing")
        return ctrl && ctrl.state ? ctrl.state.currentTime : null
      })()
    JS
  end

  def audio_time
    page.evaluate_script("document.querySelector('#minimal-player audio').currentTime")
  end

  def wait_until(timeout: Capybara.default_max_wait_time)
    deadline = Time.current + timeout
    until yield
      raise "condition not met within #{timeout}s" if Time.current > deadline

      sleep 0.05
    end
  end

  describe "a song ending while the big player is closed" do
    before do
      attach_sample_audio(song1, song2)
      start_playing(song1)
    end

    it "plays the next song in the mini player without reopening the big player" do
      click_link "Close player"
      expect(page).to have_no_css("#player", visible: :all, wait: 5)
      expect(page).to have_css("#minimal-player", visible: true)

      # The Pause label shows before the file has loaded; wait for real
      # playback, then jump to the end so `ended` advances the queue.
      wait_until { audio_time > 0 }
      page.execute_script(<<~JS)
        const el = document.getElementById("minimal-player")
        window.Stimulus.getControllerForElementAndIdentifier(el, "now-playing").seekToPercent(99)
      JS

      expect(page).to have_css(".minimal-player__name", text: song2.name, wait: 10)
      expect(page).to have_no_css("#player", visible: :all)
      expect(page).to have_no_css("body.is-big-player")
      expect(page).to have_css("#minimal-player", visible: true)
    end
  end

  describe "Previous with audio playing" do
    before do
      attach_sample_audio(song1, song2)
      start_playing(song2)
    end

    it "past the first 5 seconds, the first press restarts the song and the second goes back" do
      # The Pause label shows on the `play` event, before the file has loaded;
      # a seek issued that early is dropped. Wait for real playback first.
      wait_until { audio_time > 0 }
      page.execute_script("document.querySelector('#minimal-player audio').currentTime = 20")
      wait_until { controller_time.to_f > 5 }

      click_button "Previous"

      wait_until { audio_time < 3 }
      expect(controller_time).to be < 3
      expect(page).to have_link(song2.name)

      click_button "Previous"

      expect(page).to have_link(song1.name, wait: 5)
    end

    it "within the first 5 seconds, a press goes straight to the previous track" do
      expect(controller_time.to_f).to be <= 5

      click_button "Previous"

      expect(page).to have_link(song1.name, wait: 5)
    end
  end

  it "records a play history entry when the player opens" do
    expect {
      visit player_path(song1, source: SongQueue::SOURCE_ALBUM)
      expect(page).to have_link(song1.name, wait: 5)
    }.to change { user.play_histories.count }.by(1)
  end
end
