# frozen_string_literal: true

# AlbumSongsController
class AlbumSongsController < ApplicationController
  before_action :load_album, only: %i[update_position]

  def update_position
    authorize @album, :sort_songs?

    song = @album.songs.find_by(id: params[:id])
    return head :not_found unless song

    position = params[:position].to_i
    return head :unprocessable_content if position < 1

    song.insert_at(position)
    head :ok
  end

  private

  def load_album
    @album = Album.includes(:author).friendly.find(params[:album_id])
  end
end
