# frozen_string_literal: true

class PlaylistFollowsController < ApplicationController
  before_action :load_follow, only: :update_position

  def update_position
    position = params[:position].to_i
    return head :unprocessable_content if position < 1

    @follow.insert_at(position)
    head :ok
  end

  private

  def load_follow
    @follow = current_user.playlist_follows.find(params[:id])
  end
end
