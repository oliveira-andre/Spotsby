# frozen_string_literal: true

class SongActionsController < ApplicationController
  before_action :load_song, only: :show

  def show
    @saved_song_playlsit = current_user.playlists.find_by(position: 0)
    @playlists = current_user.playlists.where.not(position: 0).ordered
  end

  private

  def load_song
    @song = Song.friendly.find(params[:song_id])
  end
end
