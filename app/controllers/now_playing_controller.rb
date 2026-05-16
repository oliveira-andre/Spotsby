# frozen_string_literal: true

class NowPlayingController < ApplicationController
  def play
    current_user.update!(active_session_id: Current.session.id)
    broadcast_active_device
    broadcast_play_state(playing: true)
    head :no_content
  end

  def pause
    broadcast_play_state(playing: false)
    head :no_content
  end

  def active_device
    target = current_user.sessions.find(params[:session_id])
    current_user.update!(active_session_id: target.id)
    broadcast_active_device

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "now-playing-devices",
          partial: "shared/now_playing_devices",
          locals: { user: current_user,
                    sessions: current_user.sessions.listable_for(Current.session).order(:last_seen_at) }
        )
      end
      format.html { head :no_content }
    end
  end

  private

  def broadcast_active_device
    Turbo::StreamsChannel.broadcast_replace_to(
      current_user, :now_playing,
      target: "now-playing-active-device",
      partial: "shared/now_playing_active_device",
      locals: { user: current_user }
    )
  end

  def broadcast_play_state(playing:)
    Turbo::StreamsChannel.broadcast_action_to(
      current_user, :now_playing,
      action: "replace", target: "now-playing-state",
      content: view_context.tag.div(
        "", id: "now-playing-state",
        data: { controller: "play-state-relay",
                "play-state-relay-playing-value": playing.to_s }
      )
    )
  end
end
