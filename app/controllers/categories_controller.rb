# frozen_string_literal: true

# CategoriesController
class CategoriesController < ApplicationController
  def show
    @category = Category.friendly.find(params[:id])
    albums = @category.albums
                      .with_attached_image
                      .includes(songs: [:authors, { image_attachment: :blob }])
    @pagy, @albums = pagy(albums, limit: DEFAULT_PER_PAGE)
  end
end
