require 'rails_helper'

RSpec.describe CategoriesController, type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  context 'when not authenticated' do
    it 'redirects to login' do
      get category_path(category)
      expect(response).to redirect_to(new_session_path)
    end
  end

  context 'when authenticated' do
    before { sign_in(user) }

    describe 'GET /categories/:id' do
      it 'renders the category' do
        create(:album, category: category)
        get category_path(category)
        expect(response).to have_http_status(:ok)
      end

      it 'finds by slug' do
        get category_path(category.slug)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'pagination ordering' do
      # Album#position is scoped per author (acts_as_list scope: :author), so every
      # author's albums start at position 1. A category spanning multiple authors
      # therefore has colliding positions, and ordering by position alone is not a
      # total order — under LIMIT/OFFSET, Postgres can repeat or drop rows across
      # pages. The controller adds an :id tiebreaker to keep paging deterministic.
      it 'paginates a multi-author category without repeating or dropping albums' do
        authors = create_list(:author, 3)
        albums  = authors.flat_map { |a| create_list(:album, 5, category: category, author: a) }
        # 15 albums, DEFAULT_PER_PAGE = 10 => 2 pages, positions 1..5 repeated per author.

        expected = albums.sort_by { |al| [ al.position, al.id ] }.map(&:name)

        rendered = (1..2).flat_map do |page|
          get category_path(category, page: page)
          expect(response).to have_http_status(:ok)
          album_names_in(response.body)
        end

        expect(rendered).to eq(expected)                 # exact, deterministic total order
        expect(rendered.uniq.size).to eq(rendered.size)  # no album on two pages
        expect(rendered).to match_array(albums.map(&:name)) # every album shown once
      end
    end
  end

  # Album names visible in the main content. Scoped to #page-content so the hidden
  # bottom-modal (which the layout renders as a sibling) can't double the count.
  def album_names_in(body)
    Nokogiri::HTML(body).css('#page-content .album-block__name').map { |n| n.text.strip }
  end
end
