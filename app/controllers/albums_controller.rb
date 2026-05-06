# frozen_string_literal: true

# AlbumsController
class AlbumsController < ApplicationController
  before_action :load_album, only: %i[show random_song]

  def show; end

  def random_song
    song = @album.songs.sample
    return redirect_to album_path(@album) unless song

    redirect_to player_path(song, source: SongQueue::SOURCE_ALBUM)
  end

  private

  def load_album
    @album = Rails.cache.fetch("album_#{params[:id]}") do
      Album.with_attached_image
                    .includes(:author, :category, songs: [ :authors, { image_attachment: :blob } ])
                    .friendly
                    .find(params[:id])
    end
  end
end
