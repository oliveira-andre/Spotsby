# frozen_string_literal: true

# HomeController
class HomeController < ApplicationController
  def index; end

  def search
    @categories = Rails.cache.fetch("categories") do
      Category.with_attached_image.ordered
    end

    @play_histories = current_user.play_histories
                                  .from_search
                                  .includes(song: [:authors, :album, { image_attachment: :blob }])
                                  .recent
                                  .limit(20)
  end

  def search_results
    query = params[:q].to_s.strip

    if query.blank?
      @songs = Song.none
      @albums = Album.none
      @authors = Author.none
    else
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"

      @songs = Song.where("name ILIKE :p OR lyrics ILIKE :p", p: pattern)
                   .with_attached_image
                   .includes(:album, :authors)
                   .limit(20)

      @albums = Album.where("name ILIKE ?", pattern)
                     .with_attached_image
                     .includes(:author)
                     .limit(20)

      @authors = Author.where("name ILIKE ?", pattern)
                       .with_attached_image
                       .limit(20)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "search_results",
          partial: "home/search_results"
        )
      end
    end
  end

  def library
    @playlists = current_user.playlists
                             .with_attached_image
                             .with_songs_count
                             .ordered
  end

  def manage; end
end
