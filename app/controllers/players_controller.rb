# frozen_string_literal: true

# PlayersController
class PlayersController < ApplicationController
  before_action :load_song

  def show; end

  private

  def load_song
    @song = nil
    return unless params[:song_id].present? || params[:id].present?

    slug = params[:song_id].presence || params[:id]
    @song = Song.friendly.find(slug)
  rescue ActiveRecord::RecordNotFound
    @song = nil
  end
end
