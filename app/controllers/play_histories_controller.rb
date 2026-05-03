# frozen_string_literal: true

# PlayHistoriesController
class PlayHistoriesController < ApplicationController
  before_action :load_play_history, only: %i[destroy]

  def destroy
    @play_history.destroy

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def load_play_history
    @play_history = current_user.play_histories.find(params[:id])
  end
end
