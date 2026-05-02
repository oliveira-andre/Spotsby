# frozen_string_literal: true

# AlbumsController
class AlbumsController < ApplicationController
  before_action :load_album, only: %i[show]

  def show; end

  private

  def load_album
    @album = Rails.cache.fetch("album_#{params[:id]}") do
      Album.with_attached_image
                    .includes(:author, :category, songs: [:authors, { image_attachment: :blob }])
                    .friendly
                    .find(params[:id])
    end
  end
end
