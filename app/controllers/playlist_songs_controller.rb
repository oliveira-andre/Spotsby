# frozen_string_literal: true

# PlaylistSongsController
class PlaylistSongsController < ApplicationController
  before_action :load_playlist, only: %i[update_position]

  def update_position
    authorize @playlist, :sort_songs?

    playlist_song = @playlist.playlist_songs.find_by(song_id: params[:id])
    return head :not_found unless playlist_song

    playlist_song.insert_at(params[:position].to_i)
    head :ok
  end

  private

  def load_playlist
    @playlist = current_user.playlists.friendly.find(params[:playlist_id])
  end
end
