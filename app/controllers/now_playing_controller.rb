# frozen_string_literal: true

class NowPlayingController < ApplicationController
  include NowPlayingBroadcasts

  def play
    if current_user.active_session_id.nil?
      current_user.update!(active_session_id: Current.session.id)
      broadcast_active_device
    end
    broadcast_play_state(playing: true)
    render_devices_or_head
  end

  def pause
    broadcast_play_state(playing: false)
    render_devices_or_head
  end

  def active_device
    target = current_user.sessions.find(params[:session_id])
    current_user.update!(active_session_id: target.id)
    broadcast_active_device
    render_devices_or_head
  end

  def devices
    render_devices_or_head
  end

  private

  def render_devices_or_head
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "now-playing-devices",
          partial: "shared/now_playing_devices",
          locals: { user: current_user,
                    sessions: current_user.sessions.listable_for(Current.session).order(:last_seen_at) }
        )
      end
      format.any { head :no_content }
    end
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
