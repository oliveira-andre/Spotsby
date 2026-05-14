# frozen_string_literal: true

class PopularSongsController < ApplicationController
  before_action :load_author, only: %i[update_position]

  def update_position
    authorize @author, :sort_popular_songs?

    popular_song = @author.popular_songs.find_by(id: params[:id])
    return head :not_found unless popular_song

    position = params[:position].to_i
    return head :unprocessable_content if position < 1

    popular_song.insert_at(position)
    head :ok
  end

  private

  def load_author
    @author = Author.friendly.find(params[:author_id])
  end
end
