require "rails_helper"

RSpec.describe "Home & navigation", type: :system do
  let(:user) { create(:user) }

  before { sign_in_as(user) }

  it "lands on the home page after login" do
    expect(page).to have_current_path(root_path)
    expect(page).to have_selector("[role='tab']", text: "All")
    expect(page).to have_selector("[role='tab']", text: "Albums")
    expect(page).to have_selector("[role='tab']", text: "Artists")
  end

  it "renders the empty home feed for a brand-new user" do
    expect(page).to have_text("Too quiet, start listening some music")
  end

  it "exposes the primary bottom navigation" do
    within("nav[aria-label='Primary']") do
      expect(page).to have_link("Home",    href: root_path)
      expect(page).to have_link("Search",  href: search_path)
      expect(page).to have_link("Library", href: library_path)
      expect(page).to have_link("Create",  href: manage_path)
    end
  end

  it "navigates to the library and shows the auto-created Saved Songs playlist" do
    visit library_path

    expect(page).to have_current_path(library_path)
    expect(page).to have_css("h1", text: "Your Library")
    saved_link = find_link(href: playlist_path(user.saved_songs_playlist))
    expect(saved_link).to have_text("Saved Songs")
    expect(saved_link).to have_text("0 songs")
  end

  it "opens the user sidebar and can log out" do
    find("button[aria-label='Open menu']").click

    expect(page).to have_css("[data-sidebar-open='true']", wait: 5)
    expect(page).to have_text(user.email_address)

    click_button "Log out"

    expect(page).to have_current_path(new_session_path, wait: 5)
  end

  it "renders recent_albums and recent_artists without errors" do
    visit recent_albums_path
    expect(page).to have_no_text("We're sorry")

    visit recent_artists_path
    expect(page).to have_no_text("We're sorry")
  end
end
