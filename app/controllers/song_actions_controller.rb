# frozen_string_literal: true

class SongActionsController < ApplicationController
  def show
    @song = Song.friendly.find(params[:song_id])
  end
end
