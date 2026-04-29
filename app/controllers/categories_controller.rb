# frozen_string_literal: true

# CategoriesController
class CategoriesController < ApplicationController
  ALBUMS_PER_PAGE = 10

  def show
    @category = Category.friendly.find(params[:id])
    @albums = @category.albums
                       .with_attached_image
                       .includes(songs: [:authors, { image_attachment: :blob }])
                       .order(created_at: :desc)
                       .limit(ALBUMS_PER_PAGE)
  end
end
