# frozen_string_literal: true

class SongQueuesController < ApplicationController
  def create
    @song = Song.friendly.find(params[:song_id])
    SongQueueing.new(current_user).enqueue(@song)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to(root_path, notice: "Added to queue") }
    end
  end
end
