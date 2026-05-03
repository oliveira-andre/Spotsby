# frozen_string_literal: true

# PlaylistsController
class PlaylistsController < ApplicationController
  before_action :load_playlist, only: %i[show]

  def show; end

  private

  def load_playlist
    @playlist = current_user.playlists
                            .with_attached_image
                            .friendly
                            .find(params[:id])
    @playlist_songs = @playlist.playlist_songs
                               .includes(song: [:authors, :album, { image_attachment: :blob }])
                               .ordered
  end
end
