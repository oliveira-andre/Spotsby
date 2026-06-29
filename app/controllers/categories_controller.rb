# frozen_string_literal: true

# CategoriesController
class CategoriesController < ApplicationController
  def show
    @category = Category.friendly.find(params[:id])
    albums = @category.albums
                      .order(:id) # `ordered` sorts by position, but acts_as_list scopes
                                  # position per author, so it collides within a category.
                                  # Add id as a stable tiebreaker so LIMIT/OFFSET paging
                                  # can't repeat or skip albums across pages.
                      .with_attached_image
                      .includes(songs: [ :authors, { image_attachment: :blob } ])
    @pagy, @albums = pagy(albums, limit: DEFAULT_PER_PAGE)
  end
end
