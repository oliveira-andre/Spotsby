require "rails_helper"

RSpec.describe "Search", type: :system do
  let(:user) { create(:user) }

  before do
    create(:category, name: "Rock")
    create(:category, name: "Pop")

    @author = create(:author, name: "Searchable Artist")
    @album  = create(:album,  name: "Searchable Album", author: @author)
    @song   = create(:song,   name: "Searchable Song",  album: @album)

    sign_in_as(user)
  end

  it "shows browse-all categories on the search page" do
    visit search_path

    expect(page).to have_css("h2", text: "Browse all")
    expect(page).to have_link("Rock", href: category_path("rock"))
    expect(page).to have_link("Pop",  href: category_path("pop"))
  end

  it "renders matching results for a query" do
    visit search_path
    fill_in "Search", with: "Searchable"

    expect(page).to have_link(@author.name, href: author_path(@author))
    expect(page).to have_link(@album.name,  href: album_path(@album))
    expect(page).to have_link(@song.name,   href: %r{players/#{@song.slug}})
  end

  it "lets the user open an artist from the search results" do
    visit search_path
    fill_in "Search", with: "Searchable"

    expect(page).to have_link(@author.name, href: author_path(@author), wait: 5)
    find_link(href: author_path(@author)).click

    expect(page).to have_css("h1", text: @author.name, wait: 5)
  end

  it "keeps a replayed song in the recent searches history only once" do
    play_song_from_search
    play_song_from_search

    visit search_path
    find("input[aria-label='Search']").click # focus reveals the history panel

    within("#play_histories") do
      expect(page).to have_css("li", text: @song.name, count: 1, wait: 5)
    end
  end

  def play_song_from_search
    visit search_path
    fill_in "Search", with: "Searchable"

    find_link(@song.name, href: %r{players/#{@song.slug}}, wait: 5).click
    expect(page).to have_link(@song.name, wait: 5) # player rendered
  end
end
